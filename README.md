# ct_sprints_iimura

# Sprint2

## Network

- VPC(10.0.0.0/21)
- InternetGateway(web/api-routetable にアタッチ)
- web-subnet-01(10.0.0.0/24,Public,web-routetable)
- api-subnet-01(10.0.1.0/24,Public,api-routetable)
- db-subnet-01(10.0.2.0/24,Private,db-routetable)

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
- RDS サーバ
  - Aurora MySQL
  - db.t3.small
  - mysql5.7

## Function

- WebSV -> APISV 接続
- APISV -> RDS 接続

## Sprint1

- 要件: Web アプリケーション起動および"API Test"の正常動作
- 結果:
  - Terraform で構成作成
  - user_data.sh.tmpl を使って自動化
    - スクリプト作成
    - 値の渡し方(templatefile,ヒアドキュメント)
