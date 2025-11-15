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

# Webサブネットを作成
resource "aws_subnet" "web_aws_subnet_01" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
}

# IGWを作成
resource "aws_internet_gateway" "reservation_ig" {
  vpc_id = aws_vpc.sprints_network.id
}

# Public Subnetのルートテーブル
resource "aws_route_table" "web_routetable" {
  vpc_id = aws_vpc.sprints_network.id
}

# IGW向けのルート設定
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.web_routetable.id
  gateway_id             = aws_internet_gateway.reservation_ig.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "api_default" {
  route_table_id         = aws_route_table.api_routetable.id
  gateway_id             = aws_internet_gateway.reservation_ig.id
  destination_cidr_block = "0.0.0.0/0"
}

# Public Subnetのルートテーブルとサブネットの紐付
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.web_aws_subnet_01.id
  route_table_id = aws_route_table.web_routetable.id
}

# APIサブネットを作成
resource "aws_subnet" "api_subnet_01" {
  vpc_id                  = aws_vpc.sprints_network.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

# APIサブネットのルートテーブル
resource "aws_route_table" "api_routetable" {
  vpc_id = aws_vpc.sprints_network.id
}

# APIサブネットのルートテーブルとサブネットの紐付け
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.api_subnet_01.id
  route_table_id = aws_route_table.api_routetable.id
}
