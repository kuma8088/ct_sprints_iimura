# ct_sprints_iimura

## Sprints

- [x] Sprint1: Network and Servers
- [x] Sprint2: RDS and Authentication
- [ ] Sprint3: Redundancy (ALB/Auto Scaling)
- [ ] Sprint4: Contents Delivery
      (Cloudfront/Route53/CertificateManager/s3-Webfront)
- [ ] Sprint5: Container (ECR/ECS/Fargate/NAT)
- [ ] Sprint6: DevOps (CodePipeline/CodeBuild/CodeDeploy)

## Network

```mermaid
flowchart LR
%%外部要素のUser
INET((Internet))
IGW[IGW]

%%グループとサービス
subgraph GC[AWS]
  subgraph GR[Region:Tokyo]
    subgraph GV[VPC:10.0.0.0/21]
      subgraph GA[AZ:1a]
        subgraph GS1[elb-subnet-1/2_pub 10.0.5.0/24 10.0.6.0/24]
          NW1{{ELB<br>api-alb}}
        end
        subgraph GS2[web-subnet-1_pub<br>10.0.0.0/24]
          CP1[EC2:Web]
        end
        subgraph GS3[api-subnet-1_pri<br>10.0.1.0/24]
          CP2("EC2:api1")
        end
        subgraph GS5[db-subnet-group_pri<br>10.0.2.0/23]
          DB1[("RDS")]
        end
      end
      subgraph GA[AZ:1c]
        subgraph GS4[api-subnet-2_pri<br>10.0.4.0/24]
          CP3("EC2:api2")
        end
      end
    end
  end
end

%%サービス同士の関係
INET --> IGW
IGW --> NW1
IGW --> CP1
NW1 --> CP2
NW1 --> CP3
CP2 --> DB1

%%---スタイルの設定---
%%AWS Cloudのスタイル
classDef SGC fill:none,color:#345,stroke:#345
class GC SGC

%%Regionのスタイル
classDef SGR fill:none,color:#59d,stroke:#59d,stroke-dasharray:3
class GR SGR

%%VPCのスタイル
classDef SGV fill:none,color:#0a0,stroke:#0a0
class GV SGV

%%Availability Zoneのスタイル
classDef SGA fill:none,color:#59d,stroke:#59d,stroke-width:1px,stroke-dasharray:8
class GA SGA

%%Private subnetのスタイル
classDef SGPrS fill:#def,color:#07b,stroke:none
class GS3 SGPrS
class GS4 SGPrS
class GS5 SGPrS


%%Public subnetのスタイル
classDef SGPuS fill:#efe,color:#092,stroke:none
class GS1 SGPuS
class GS2 SGPuS

%%---スタイルの設定---

%%外部要素のスタイル
classDef SOU fill:#aaa,color:#fff,stroke:#fff
class OU1,OU2,OU3 SOU

%%Network関連のスタイル
classDef SNW fill:#84d,color:#fff,stroke:none
class NW1,NW2,NW3 SNW

%%Compute関連のスタイル
classDef SCP fill:#e83,color:#fff,stroke:none
class CP1,CP2,CP3 SCP

%%DB関連のスタイル
classDef SDB fill:#46d,color:#fff,stroke:#fff
class DB1,DB2,DB3 SDB

%%Storage関連のスタイル
classDef SST fill:#493,color:#fff,stroke:#fff
class ST1,ST2,ST3 SST

%%グループのスタイル
classDef SG fill:none,color:#666,stroke:#aaa
class GST,GDB,GCP,GNW,GOU SG
```

- VPC (10.0.0.0/21)
- InternetGateway (sprints_reservation_ig)
- web-subnet-01 (10.0.0.0/24, Public, web-routetable)
- api-subnet-01 (10.0.1.0/24, Public, api-routetable)
- db-subnet-01 (10.0.2.0/24, Private, db-routetable, db-subnet-group)
- db-subnet-02 (10.0.3.0/24, Private, db-routetable, db-subnet-group)

- WEB 各サーバには個別の EIP を割り当て、ブラウザから直接アクセス

## Compute

- API サーバ #Spring1/2
  - api-server-01
  - AmazonLinux
  - EIP
  - Nginx/Go/git/mysql
- WEB サーバ #Spring1
  - web-server-01
  - AmazonLinux
  - EIP
  - Nginx/git
- RDS サーバ(Multi AZ) #Sprint2
  - Aurora MySQL
  - db.t3.small
  - mysql8.0

## Todo

- [x] api-subnet-02 作成
- [x] api-subnet-01 Private 設定(routetable 変更)
- [x] api-server-02 作成
- [x] alb-subnet 作成
- [x] ALB 作成(TargetGroup/Listner)
- [x] web-server 設定変更(config.js)
- [x] auto-scaling 設定
- [ ] 起動確認・動作確認

### Sprint1

- 要件: Web アプリケーション起動および"API Test"の正常動作
- 結果:
  - Terraform で構成作成
  - user_data.sh.tmpl を使って自動化
    - スクリプト作成
    - 値の渡し方(templatefile,ヒアドキュメント)

### Sprint2

- サーバ作成順（depends_on）
- 変数利用（variables.tf,terraform.tfvars）
- user_data.sh の失敗で停止(set -euo pipefail)
- user_data.sh のパッケージインストール失敗を保険(for,if,etc)
- user_data.sh で DB 接続を確認して後続処理を走らせる(until)
- user_data.sh で特定 PID を変数にして kill する処理
- user_data.sh の処理待ちの確認(EC2: Actions-"Monitor and troubleshoot"-"Get system log")
