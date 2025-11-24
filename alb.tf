# ALB
resource "aws_lb" "api_alb" {
  name                       = "api-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.sprints_elb_01.id,
    aws_subnet.sprints_elb_02.id,
  ]
  security_groups = [
    aws_security_group.sprints_alb_sg.id
  ]
}

# SecurityGroup
resource "aws_security_group" "sprints_alb_sg" {
  name   = "sprints_alb_sg"
  vpc_id = aws_vpc.sprints_network.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB Listener
# ## HTTP
# resource "aws_lb_listener" "api_alb_listener" {
#   load_balancer_arn = aws_lb.api_alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.sprints_api_alb_target_group.arn
#   }
# }

## HTTPS
resource "aws_lb_listener" "api_alb_listener_https" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate.sprints_api_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sprints_api_alb_target_group.arn
  }
}

# ALB TargetGroup
resource "aws_lb_target_group" "sprints_api_alb_target_group" {
  name                 = "sprints-ecs-alb-target-group"
  target_type          = "ip"
  vpc_id               = aws_vpc.sprints_network.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  tags = {
    Name = "sprints-ecs-alb-target-group"
  }
}

# ALB TargetGroup (Green)
resource "aws_lb_target_group" "sprints_api_alb_target_group_green" {
  name                 = "sprints-ecs-alb-tg-green"
  target_type          = "ip"
  vpc_id               = aws_vpc.sprints_network.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  tags = {
    Name = "sprints-ecs-alb-tg-green"
  }
}

# ALB Listener (Test / Green)
resource "aws_lb_listener" "api_alb_listener_https_test" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = 8080
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate.sprints_api_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sprints_api_alb_target_group_green.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.api_alb.dns_name
}
