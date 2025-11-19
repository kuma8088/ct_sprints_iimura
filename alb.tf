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
    aws_security_group.sprints_alb_sg
  ]
}

# SecurityGroup
resource "aws_security_group" "sprints_alb_sg" {
  name   = "sprints_alb_sg"
  vpc_id = aws_vpc.sprints_network.id

  ingress {
    from_port   = 80
    to_port     = 80
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
resource "aws_lb_listener" "api_alb_listener" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sprints_api_alb_target_group.arn
  }
}

# ALB TargetGroup
resource "aws_lb_target_group" "sprints_api_alb_target_group" {
  name                 = "api-alb-target-group"
  target_type          = "instance"
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

  depends_on = [aws_lb.api_alb]
}

output "alb_dns_name" {
  value = aws_lb.api_alb.dns_name
}
