# ct_sprints_iimura

# Sprint1

## Network

- VPC(10.0.0.0/21)
- InternetGateway(web/api-routetable にアタッチ)
- web-subnet-01(10.0.0.0/24,Public,web-routetable)
- api-subnet-01(10.0.1.0/24,Public,api-routetable)

## Compute

- API サーバ
  - api-server-01
  - AmazonLinux
  - EIP
  - Nginx/Go/git
- WEB サーバ
  - web-server-01
  - AmazonLinux
  - EIP
  - Nginx/git

## Requirements

- Web アプリケーション起動および"API Test"の正常動作
