# ---------------------------------------------
# プロバイダー定義
# ---------------------------------------------
# デフォルトのプロバイダー
provider "aws" {
  region = "ap-northeast-1"
}

# ACM証明書用: us-east-1 のエイリアスプロバイダーを定義
provider "aws" {
  alias  = "us_east_1" # エイリアス名
  region = "us-east-1"
}

# ルートドメインとサブドメインを変数として定義
locals {
  domain_name = aws_route53_zone.sprints_zone.name
}
