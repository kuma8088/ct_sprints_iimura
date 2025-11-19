provider "aws" {
  region = "ap-northeast-1"
}

# VPCを作成
resource "aws_vpc" "sprints_network" {
  cidr_block           = "10.0.0.0/21"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "sprints-network"
  }
}

## IGWを作成
resource "aws_internet_gateway" "sprints_reservation_ig" {
  vpc_id = aws_vpc.sprints_network.id
}

# ALBサブネット---------------------------------------------------------------
# ALBサブネット01(AZ:1a)を作成
resource "aws_subnet" "sprints_elb_01" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
}
# ALBサブネット02(AZ:1c)を作成
resource "aws_subnet" "sprints_elb_02" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
}

# ALBサブネットのルートテーブル
resource "aws_route_table" "sprints_elb" {
  vpc_id = aws_vpc.sprints_network.id

  tags = {
    Name = "sprints-elb-routetable"
  }
}

# IGWとルートテーブルの紐付け
resource "aws_route" "sprints_elb" {
  route_table_id         = aws_route_table.sprints_elb.id
  gateway_id             = aws_internet_gateway.sprints_reservation_ig.id
  destination_cidr_block = "0.0.0.0/0"
}

# ALBサブネット01のルートテーブルの紐付け
resource "aws_route_table_association" "sprints_elb_01" {
  subnet_id      = aws_subnet.sprints_elb_01.id
  route_table_id = aws_route_table.sprints_elb.id
}

# ALBサブネット02のルートテーブルとの紐付け
resource "aws_route_table_association" "sprints_elb_02" {
  subnet_id      = aws_subnet.sprints_elb_02.id
  route_table_id = aws_route_table.sprints_elb.id
}

# Webサブネット---------------------------------------------------------------
# Webサブネットを作成
resource "aws_subnet" "sprints_web_aws_subnet_01" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
}

# Public Subnetのルートテーブル
resource "aws_route_table" "sprints_web_routetable" {
  vpc_id = aws_vpc.sprints_network.id

  tags = {
    Name = "sprints-web-routetable"
  }
}

# Web_IGW向けのルート設定
resource "aws_route" "sprints_public_route" {
  route_table_id         = aws_route_table.sprints_web_routetable.id
  gateway_id             = aws_internet_gateway.sprints_reservation_ig.id
  destination_cidr_block = "0.0.0.0/0"
}

# Web_Public Subnetのルートテーブルとサブネットの紐付
resource "aws_route_table_association" "sprints_web" {
  subnet_id      = aws_subnet.sprints_web_aws_subnet_01.id
  route_table_id = aws_route_table.sprints_web_routetable.id
}


# APIサブネット--------------------------------------------------------------
# APIサブネット(1a)を作成
resource "aws_subnet" "sprints_api_subnet_01" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

# APIサブネット(1c)を作成
resource "aws_subnet" "sprints_api_subnet_02" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
}

## NAT Gateway
resource "aws_nat_gateway" "sprints_natgw" {
  allocation_id = aws_eip.sprints_nat_gw.id
  subnet_id     = aws_subnet.sprints_elb_01.id
  depends_on    = [aws_internet_gateway.sprints_reservation_ig]

  tags = {
    Name = "sprints-natgw"
  }
}

## NATGW用EIP
resource "aws_eip" "sprints_nat_gw" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.sprints_reservation_ig]
  tags = {
    Name = "sprints-natgw-eip"
  }
}

# API_Privateサブネットのルートテーブル
resource "aws_route_table" "sprints_api_routetable" {
  vpc_id = aws_vpc.sprints_network.id

  tags = {
    Name = "sprints-api-routetable"
  }
}

# NATGWのルート設定
resource "aws_route" "sprints_private_natgw" {
  route_table_id         = aws_route_table.sprints_api_routetable.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.sprints_natgw.id
}

# APIサブネット01のルートテーブルとサブネットの紐付け
resource "aws_route_table_association" "sprints_api_01" {
  subnet_id      = aws_subnet.sprints_api_subnet_01.id
  route_table_id = aws_route_table.sprints_api_routetable.id
}

# APIサブネット02のルートテーブルとサブネットの紐付け
resource "aws_route_table_association" "sprints_api_02" {
  subnet_id      = aws_subnet.sprints_api_subnet_02.id
  route_table_id = aws_route_table.sprints_api_routetable.id
}


# DBサブネットを作成----------------------------------------------------------
## DBサブネット1(ap-northeast-1a)
resource "aws_subnet" "sprints_db_subnet_01" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "sprints-db-subnet-01"
  }
}

## DBサブネット2(ap-northeast-1c)
resource "aws_subnet" "sprints_db_subnet_02" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "sprints-db-subnet-02"
  }
}

## DBサブネットグループ
resource "aws_db_subnet_group" "sprints_db_subnet_group" {
  name = "sprints-db-subnet-group"
  subnet_ids = [
    aws_subnet.sprints_db_subnet_01.id,
    aws_subnet.sprints_db_subnet_02.id
  ]

  tags = {
    Name = "sprints-db-subnet-group"
  }
}

# DBサブネットのルートテーブル
resource "aws_route_table" "sprints_db_routetable" {
  vpc_id = aws_vpc.sprints_network.id

  tags = {
    Name = "sprints-db-routetable"
  }
}

# DBサブネットのルートテーブルとサブネットの紐付1
resource "aws_route_table_association" "sprints_db_01" {
  subnet_id      = aws_subnet.sprints_db_subnet_01.id
  route_table_id = aws_route_table.sprints_db_routetable.id
}

# DBサブネットのルートテーブルとサブネットの紐付2
resource "aws_route_table_association" "sprints_db_02" {
  subnet_id      = aws_subnet.sprints_db_subnet_02.id
  route_table_id = aws_route_table.sprints_db_routetable.id
}
