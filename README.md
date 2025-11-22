# ct_sprints_iimura

## Sprints

- [x] Sprint1: Network and Servers
- [x] Sprint2: RDS and Authentication
- [x] Sprint3: Redundancy (ALB/Auto Scaling)
- [x] Sprint4: Contents Delivery
      (Cloudfront/Route53/CertificateManager/s3-Webfront)
- [ ] Sprint5: Container (ECR/ECS/Fargate/NAT)
- [ ] Sprint6: DevOps (CodePipeline/CodeBuild/CodeDeploy)

## Network

```mermaid
flowchart TB
%%外部要素のUser
INET((Internet))

%%グループとサービス
subgraph GC[AWS]
  DNS[Route53<br>root/api.ドメインの名前解決]
  ACM2[ACM<br>CloudFront]
  subgraph GR[Region:Tokyo]
    ACM[ACM<br>ELB]
    ST1[(WebFront)]
    subgraph GV[VPC:10.0.0.0/21]
      subgraph GA[AZ:1a]
        subgraph GS1[elb1 10.0.5.0/24]
          NW1{ELB-ENI<br>api-alb}
        end
        subgraph GS3[api1 10.0.1.0/24]
          CP2("EC2:api1")
        end
        subgraph GS5[db1 10.0.2.0/23]
          DB1[("RDS: Primary")]
        end
      end
      subgraph GB[AZ:1c]
        subgraph GS6[elb-2 10.0.6.0/24]
          NW2{ELB-ENI<br>api-alb}
        end
        subgraph GS7[api2 10.0.4.0/24]
          CP3("EC2:api2")
        end
        subgraph GS8[db2 10.0.3.0/23]
          DB2[("RDS: Secondary")]
        end
      end
    end
  end
  CF[CloudFront]
end

%%サービス同士の関係
INET --> DNS
DNS --> CF
CF --> ST1
ST1 --> NW1
ST1 --> NW2
NW1 --> CP2
NW2 --> CP3
CP2 --> DB1
CP3 --> DB1
DB1 -.- |Replication| DB2

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
class GA,GB SGA

%%Private subnetのスタイル
classDef SGPrS fill:#def,color:#07b,stroke:none
class GS3,GS4,GS5,GS7,GS8 SGPrS

%%Public subnetのスタイル
classDef SGPuS fill:#efe,color:#092,stroke:none
class GS1,GS2,GS6 SGPuS

%%---スタイルの設定---

%%外部要素のスタイル
classDef SOU fill:#aaa,color:#fff,stroke:#fff
class OU1,OU2,OU3 SOU

%%Network関連のスタイル
classDef SNW fill:#84d,color:#fff,stroke:none
class NW1,NW2,NW3,CF,DNS SNW

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

## Compute

- WEB フロント(s3)
- API サーバ (AutoScaling)
  - api-server-01
  - AmazonLinux
  - Nginx/Go/mysql
- RDS サーバ(Multi AZ)
  - Aurora MySQL
  - db.t3.small
  - mysql8.0

## Sprint5 Tasks

- [ ] ALB Listner の変更（
- [ ] 既存 AutoScaling の変更（停止）
- [x] NAT ゲートウェイの作成（既に作成済み）
- [ ] ECS タスク定義
- [ ] ECS サービス定義
- [ ] 動作確認

### Sprint4 Problem/Resolution

- 追加レコードの検証が完了しない
  ホストゾーンとレジストラの NS レコード設定が必要（ホストゾーンの作成とレコード追加・検証の同時作業は不可）
- CloudFront CNAME エラー (InvalidViewerCertificate)
  ACM 証明書が Apex ドメインのみで `www` を含んでいなかったため、CloudFront の Aliases から `www` を除外して対応
- Route53 Alias エラー (InvalidChangeBatch)
  ALB への Alias レコード作成時、`zone_id` に Route53 のゾーン ID ではなく、ALB のゾーン ID (`aws_lb.api_alb.zone_id`) を指定する必要があった
- CORS エラー (No 'Access-Control-Allow-Origin')
  API サーバー(Nginx)が CORS ヘッダーを返していなかったため、`user_data` で Nginx 設定を追加し、`Access-Control-Allow-Origin` を付与
- 設定変更が反映されない (Timeout)
  `user_data` で Nginx 設定ファイルを書き換えた後、`start` ではなく `restart` を実行しないと新設定が読み込まれない問題を修正

### Sprint3 Completed

- 課題解決

  - 起動順(DB>API>ALB>WEB)
    それぞれの依存関係およびヘルスチェックのエラー回避
  - aws_instance と aws_launch_template の ebs 設定の違い
  - alb の health_check をクリアするためのスクリプト改善
    - api-base-ami 作成し pkg インストールし依存関係のない設置値も事前に入れておく
    - launch_template からは最低限のセッティングだけを apib_user_data.sh.tmpl に入れる

- Tasks
  - [x] api-subnet-02 作成
  - [x] api-subnet-01 Private 設定(routetable 変更)
  - [x] api-server-02 作成
  - [x] alb-subnet 作成
  - [x] ALB 作成(TargetGroup/Listner)
  - [x] web-server 設定変更(config.js)
  - [x] auto-scaling 設定
  - [x] 起動確認・動作確認

### Sprint2 Completed

- サーバ作成順（depends_on）
- 変数利用（variables.tf,terraform.tfvars）
- user_data.sh の失敗で停止(set -euo pipefail)
- user_data.sh のパッケージインストール失敗を保険(for,if,etc)
- user_data.sh で DB 接続を確認して後続処理を走らせる(until)
- user_data.sh で特定 PID を変数にして kill する処理
- user_data.sh の処理待ちの確認(EC2: Actions-"Monitor and troubleshoot"-"Get system log")

### Sprint1 Completed

- 要件: Web アプリケーション起動および"API Test"の正常動作
- 結果:
  - Terraform で構成作成
  - user_data.sh.tmpl を使って自動化
    - スクリプト作成
    - 値の渡し方(templatefile,ヒアドキュメント)
