# APIサーバ
resource "aws_instance" "sprints_api_server_01" {
  ami                    = "ami-09b6ff1b8ef075ba5"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sprints_api_subnet_01.id
  vpc_security_group_ids = [aws_security_group.sprints_api_server.id]
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }
  key_name = "test-ec2-key"

  # 依存関係（rdsとの接続の必要があるため）
  depends_on = [aws_db_instance.sprints_db_instance]

  # 初期設定
  user_data = templatefile("./api_user_data.sh.tmpl", {
    db_endpoint = aws_db_instance.sprints_db_instance.address,
    db_user     = var.db_user,
    db_password = var.db_password
  })
  tags = {
    Name = "api-server-01"
  }
}

# Webサーバ
resource "aws_instance" "sprints_web_server_01" {
  ami                    = "ami-09b6ff1b8ef075ba5"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sprints_web_aws_subnet_01.id
  vpc_security_group_ids = [aws_security_group.sprints_web_server_sg.id]
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }
  key_name = "test-ec2-key"

  # 依存関係（APIサーバのEIP待ち）
  depends_on = [
    aws_instance.sprints_api_server_01,
    aws_eip_association.sprints_api_eip_association
  ]

  user_data = templatefile("./web_user_data.sh.tmpl", {
    api_base_url = "http://${aws_eip.sprints_api_eip.public_ip}"
  })
  tags = {
    Name = "web-server-01"
  }
}

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
    Name = "sprints-api-sg"
  }
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


# EIP-webサーバ
resource "aws_eip" "sprints_web_eip" {
  domain = "vpc"
  tags = {
    Name = "web-eip"
  }
}

resource "aws_eip" "sprints_api_eip" {
  domain = "vpc"
  tags = {
    Name = "api-eip"
  }
}

resource "aws_eip_association" "sprints_web_eip_association" {
  allocation_id        = aws_eip.sprints_web_eip.allocation_id
  network_interface_id = aws_instance.sprints_web_server_01.primary_network_interface_id
}

resource "aws_eip_association" "sprints_api_eip_association" {
  allocation_id        = aws_eip.sprints_api_eip.allocation_id
  network_interface_id = aws_instance.sprints_api_server_01.primary_network_interface_id
}
