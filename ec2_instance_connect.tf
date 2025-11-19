resource "aws_security_group" "sprints_eic_endpoint_sg" {
  name   = "sprints-eic-endpoint-sg"
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
    Name = "sprints-eic-endpoint-sg"
  }
}

# resource "aws_ec2_instance_connect_endpoint" "sprints_api_eic_1a" {
#   subnet_id          = aws_subnet.sprints_api_subnet_01.id
#   security_group_ids = [aws_security_group.sprints_eic_endpoint_sg.id]
#   preserve_client_ip = true

#   tags = {
#     Name = "sprints-api-eic-1a"
#   }
# }

resource "aws_ec2_instance_connect_endpoint" "sprints_api_eic_1c" {
  subnet_id          = aws_subnet.sprints_api_subnet_02.id
  security_group_ids = [aws_security_group.sprints_eic_endpoint_sg.id]
  preserve_client_ip = true

  tags = {
    Name = "sprints-api-eic-1c"
  }
}
