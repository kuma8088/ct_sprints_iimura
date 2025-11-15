# APIサーバ
resource "aws_instance" "api_server_01" {
  ami                    = "ami-09b6ff1b8ef075ba5"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.api_subnet_01.id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  key_name               = "test-ec2-key"
  user_data = templatefile("./api_user_data.sh", {
    api_base_url = "http://${aws_eip.api.public_ip}"
  })
  tags = {
    Name = "api-server-01"
  }
}

# Webサーバ
resource "aws_instance" "web_server_01" {
  ami                    = "ami-09b6ff1b8ef075ba5"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web_aws_subnet_01.id
  vpc_security_group_ids = [aws_security_group.web_server.id]
  key_name               = "test-ec2-key"
  user_data              = file("./web_user_data.sh")
  tags = {
    Name = "web-server-01"
  }
}

# セキュリティグループ
resource "aws_security_group" "web_server" {
  name   = "web-server"
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
}

# EIP-webサーバ
resource "aws_eip" "web" {
  domain = "vpc"
  tags = {
    Name = "web-eip"
  }
}

resource "aws_eip" "api" {
  domain = "vpc"
  tags = {
    Name = "api-eip"
  }
}

resource "aws_eip_association" "web" {
  allocation_id        = aws_eip.web.allocation_id
  network_interface_id = aws_instance.web_server_01.primary_network_interface_id
}

resource "aws_eip_association" "api" {
  allocation_id        = aws_eip.api.allocation_id
  network_interface_id = aws_instance.api_server_01.primary_network_interface_id
}

output "api_eip" {
  value = aws_eip.api.address
}
