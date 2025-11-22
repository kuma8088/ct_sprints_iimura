# ------------------------------------------------------------------
# 1. ACM証明書の取得
# ------------------------------------------------------------------
resource "aws_acm_certificate" "sprints_api_cert" {
  domain_name       = "api.${var.domain_name}"
  validation_method = "DNS"
  subject_alternative_names = [
    "api.${var.domain_name}"
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------
# 2. Route53 検証レコードの作成と検証
# ------------------------------------------------------------------
resource "aws_route53_record" "sprints_api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.sprints_api_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  name            = each.value.name
  type            = each.value.type
  zone_id         = aws_route53_zone.sprints_zone.zone_id
  ttl             = 60
  records         = [each.value.value]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "sprints_api_cert_validation_wait" {
  certificate_arn         = aws_acm_certificate.sprints_api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.sprints_api_cert_validation : record.fqdn]
}

# ------------------------------------------------------------------
# 3. Route53とACM証明書を紐付ける
# ------------------------------------------------------------------
resource "aws_route53_record" "sprints_api_alias" {
  zone_id = aws_route53_zone.sprints_zone.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.api_alb.dns_name
    zone_id                = aws_route53_zone.sprints_zone.zone_id
    evaluate_target_health = true
  }
}

# # APIサーバ_01
# resource "aws_instance" "sprints_api_server_01" {
#   ami                    = "ami-09b6ff1b8ef075ba5"
#   instance_type          = "t3.micro"
#   subnet_id              = aws_subnet.sprints_api_subnet_01.id
#   vpc_security_group_ids = [aws_security_group.sprints_api_server.id]
#   root_block_device {
#     volume_size           = 8
#     volume_type           = "gp3"
#     delete_on_termination = true
#   }
#   key_name = "test-ec2-key"

#   # 依存関係（rdsとの接続の必要があるため）
#   depends_on = [aws_db_instance.sprints_db_instance]

#   # 初期設定
#   user_data = templatefile("./api_user_data.sh.tmpl", {
#     db_endpoint = aws_db_instance.sprints_db_instance.address,
#     db_user     = var.db_user,
#     db_password = var.db_password
#   })
#   tags = {
#     Name = "api-server-01"
#   }
# }

# # APIサーバ_02
# resource "aws_instance" "sprints_api_server_02" {
#   ami                    = "ami-09b6ff1b8ef075ba5"
#   instance_type          = "t3.micro"
#   subnet_id              = aws_subnet.sprints_api_subnet_02.id
#   vpc_security_group_ids = [aws_security_group.sprints_api_server.id]
#   root_block_device {
#     volume_size           = 8
#     volume_type           = "gp3"
#     delete_on_termination = true
#   }
#   key_name = "test-ec2-key"

#   # 依存関係（rdsとの接続の必要があるため）
#   depends_on = [aws_db_instance.sprints_db_instance]

#   # 初期設定
#   user_data = templatefile("./api_user_data.sh.tmpl", {
#     db_endpoint = aws_db_instance.sprints_db_instance.address,
#     db_user     = var.db_user,
#     db_password = var.db_password
#   })
#   tags = {
#     Name = "api-server-02"
#   }
# }

# APIサーバ Auto Scaling---------------------------------------------------------------

# APIサーバ Launch Template
resource "aws_launch_template" "sprints_api_lt" {
  name                   = "sprints-api-launch-template"
  image_id               = "ami-0eefe01a65df4e4f3"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sprints_api_server.id]
  key_name               = "test-ec2-key"
  user_data = base64encode(
    templatefile("./apib_user_data.sh.tmpl", {
      db_endpoint = aws_db_instance.sprints_db_instance.address,
      db_user     = var.db_user,
      db_password = var.db_password
    })
  )
  depends_on = [aws_db_instance.sprints_db_instance]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "api-launch-template"
    }
  }
}

# APIサーバ Auto Scaling group
resource "aws_autoscaling_group" "sprints_api_asg" {
  name                      = "sprints-api-asg"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_template {
    id = aws_launch_template.sprints_api_lt.id
  }
  vpc_zone_identifier = [
    aws_subnet.sprints_api_subnet_01.id,
    aws_subnet.sprints_api_subnet_02.id
  ]
  target_group_arns = [aws_lb_target_group.sprints_api_alb_target_group.arn]
}

# AutoScalingPolicy
resource "aws_autoscaling_policy" "sprints_api_asg_policy" {
  name                   = "sprints-api-asg-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.sprints_api_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
}

# # Webサーバ ------------------------------------------------------------------------------
# resource "aws_instance" "sprints_web_server_01" {
#   ami                    = "ami-09b6ff1b8ef075ba5"
#   instance_type          = "t3.micro"
#   subnet_id              = aws_subnet.sprints_web_aws_subnet_01.id
#   vpc_security_group_ids = [aws_security_group.sprints_web_server_sg.id]
#   root_block_device {
#     volume_size           = 8
#     volume_type           = "gp3"
#     delete_on_termination = true
#   }
#   key_name = "test-ec2-key"

#   user_data = templatefile("./web_user_data.sh.tmpl", {
#     alb_base_url = "http://${aws_lb.api_alb.dns_name}"
#   })
#   depends_on = [aws_lb.api_alb]
#   tags = {
#     Name = "web-server-01"
#   }
# }

# セキュリティグループ_Webサーバ
resource "aws_security_group" "sprints_web_server_sg" {
  name   = "web-server-sg"
  vpc_id = aws_vpc.sprints_network.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sprints-web-sg"
  }
}

# セキュリティグループ_APIサーバ
resource "aws_security_group" "sprints_api_server" {
  name   = "api-server-sg"
  vpc_id = aws_vpc.sprints_network.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sprints-api-sg"
  }
}

# APIサーバのセキュリティグループルール
resource "aws_security_group_rule" "sprints_api_sg_rule" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sprints_alb_sg.id
  security_group_id        = aws_security_group.sprints_api_server.id
}

# DBサーバセキュリティグループ
resource "aws_security_group" "sprints_db_server_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.sprints_network.id

  tags = {
    Name = "sprints-db-sg"
  }
}

# DBサーバのセキュリティグループルール
resource "aws_security_group_rule" "sprints_db_server_sg_rule" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sprints_api_server.id
  security_group_id        = aws_security_group.sprints_db_server_sg.id
}


# # EIP-webサーバ
# resource "aws_eip" "sprints_web_eip" {
#   domain = "vpc"
#   tags = {
#     Name = "web-eip"
#   }
# }

# resource "aws_eip_association" "sprints_web_eip_association" {
#   allocation_id        = aws_eip.sprints_web_eip.allocation_id
#   network_interface_id = aws_instance.sprints_web_server_01.primary_network_interface_id
# }
