# CloudTech Sprints

AWS 上に 3 層 Web アプリケーション（Web/API/DB）を構築するハンズオンプロジェクト。
Terraform による Infrastructure as Code で、Blue-Green デプロイメント対応の CI/CD パイプラインを備えた実践的なアーキテクチャを実装。

## Sprints

- [x] Sprint1: Network and Servers
- [x] Sprint2: RDS and Authentication
- [x] Sprint3: Redundancy (ALB/Auto Scaling)
- [x] Sprint4: Contents Delivery
      (Cloudfront/Route53/CertificateManager/s3-Webfront)
- [x] Sprint5: Container (ECR/ECS/Fargate/NAT)
- [x] Sprint6: DevOps (CodePipeline/CodeBuild/CodeDeploy)
  - [x] Rolling Deployment
  - [x] Blue/Green Deployment
  - [x] Lambda 検知

## Quick Start

```bash
# 1. 変数ファイルの作成
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集して必要な値を設定

# 2. 初期化
terraform init

# 3. プラン確認
terraform plan

# 4. 適用
terraform apply
```

### 必要な変数（terraform.tfvars）

| 変数名           | 説明                      | 例                                    |
| ---------------- | ------------------------- | ------------------------------------- |
| `db_user`        | RDS 接続ユーザー名        | `admin`                               |
| `db_password`    | RDS 接続パスワード        | `your-secure-password`                |
| `region`         | AWS リージョン            | `ap-northeast-1`                      |
| `account_id`     | AWS アカウント ID         | `123456789012`                        |
| `github_repo_url`| GitHub リポジトリ URL     | `https://github.com/user/repo`        |
| `domain_name`    | カスタムドメイン名        | `example.com`                         |

## Architecture Overview

### システム構成

```
Internet
    │
    ▼
Route53 (DNS)
    │
    ├──────────────────────────────────────┐
    │                                      │
    ▼                                      ▼
CloudFront ─────► S3 (静的コンテンツ)   ALB (api.domain.com)
                                           │
                                    ┌──────┴──────┐
                                    ▼             ▼
                               ECS Fargate   ECS Fargate
                               (AZ: 1a)      (AZ: 1c)
                                    │             │
                                    └──────┬──────┘
                                           ▼
                                    RDS MySQL (Multi-AZ)
```

### CI/CD パイプライン

```
GitHub (Push) ──► CodePipeline ──► CodeBuild ──► ECR ──► CodeDeploy ──► ECS
                      │                                       │
                      │                              Blue-Green Deployment
                      │                              (ゼロダウンタイム)
                      ▼
               Lambda (DeployHook)
               デプロイメント検証
```

## Network

### VPC 構成

| リソース          | CIDR / 設定                   | 説明                           |
| ----------------- | ----------------------------- | ------------------------------ |
| **VPC**           | `10.0.0.0/21`                 | 2048 IP アドレス               |
| DNS サポート      | 有効                          | VPC 内 DNS 解決                |

### サブネット構成

| サブネット         | CIDR           | AZ              | タイプ     | 用途                    |
| ------------------ | -------------- | --------------- | ---------- | ----------------------- |
| `elb_01`           | `10.0.5.0/24`  | ap-northeast-1a | Public     | ALB                     |
| `elb_02`           | `10.0.6.0/24`  | ap-northeast-1c | Public     | ALB                     |
| `api_01`           | `10.0.1.0/24`  | ap-northeast-1a | Private    | ECS Fargate             |
| `api_02`           | `10.0.4.0/24`  | ap-northeast-1c | Private    | ECS Fargate             |
| `db_01`            | `10.0.2.0/24`  | ap-northeast-1a | Private    | RDS Primary             |
| `db_02`            | `10.0.3.0/24`  | ap-northeast-1c | Private    | RDS Standby             |

### ネットワーク図

```mermaid
flowchart TB
%%外部要素のUser
INET((Internet))
GITHUB((GitHub))

%%グループとサービス
subgraph GC[AWS]
  DNS[Route53<br>root/api resolver]
  ACM2[ACM<br>CloudFront]
  subgraph GR[Region:Tokyo]
    ACM[ACM<br>ELB]
    ST1[(WebFront)]
    ECR[ECR]
    CDP[CodeBuild]
    CDB[CodeDeploy]
    LMD[DeployHook]
    subgraph GV[VPC:10.0.0.0/21]
      NW3[NATGW]
      subgraph GA[AZ:1a]
        subgraph GS1[elb1 10.0.5.0/24]
          NW1{ELB-ENI<br>api-alb}
        end
        subgraph GS3[api1 10.0.1.0/24]
          CP2("Fargate<br>api1")
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
          CP3("Fargate<br>api2")
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
GITHUB -.- CDP
CDP -.- ECR
ECR -.- CDB
CDB -.- CP2
CDB -.- CP3
INET --> DNS
DNS --> |HTTPS| CF
CF --> ST1
ST1 --> |HTTPS| NW1
ST1 --> |HTTPS| NW2
NW1 --> CP2
NW2 --> CP3
CP2 --> DB1
CP3 --> DB1
DB1 -.- |Replication| DB2
ECR -.- NW3
NW3 -.-|Pull| CP2
NW3 -.-|Pull| CP3
LMD -.- |LifeCycleHook|CDB


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
class CP1,CP2,CP3,ECR,CDB,CDP,LMD SCP

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

### ECS (Fargate)

| 設定項目           | 値                          |
| ------------------ | --------------------------- |
| クラスター名       | `sprints-cluster`           |
| タスク定義         | `sprints-api-td`            |
| CPU / Memory       | 256 / 512 MB                |
| コンテナポート     | 80                          |
| 望ましいタスク数   | 2                           |
| デプロイ方式       | CODE_DEPLOY (Blue-Green)    |

**オートスケーリング:**
- 最小: 2、最大: 4
- スケールアウト条件: CPU 使用率 > 90%

**環境変数:**
- `API_PORT`: APIサーバーポート
- `DB_USERNAME` / `DB_PASSWORD`: RDS 認証情報
- `DB_SERVERNAME` / `DB_PORT` / `DB_NAME`: RDS 接続情報

### RDS (MySQL)

| 設定項目           | 値                          |
| ------------------ | --------------------------- |
| エンジン           | MySQL 8.0.43                |
| インスタンスクラス | db.t3.small                 |
| ストレージ         | 20 GB (gp3)、最大 100 GB    |
| Multi-AZ           | 有効                        |
| 暗号化             | 有効                        |
| バックアップ保持   | 30 日                       |

**パラメータグループ:**
- 文字セット: `utf8mb4`（日本語対応）

### S3 (静的コンテンツ)

| 設定項目           | 値                          |
| ------------------ | --------------------------- |
| バケット名         | `sprints-iimura-s3-bucket-*`|
| パブリックアクセス | 全てブロック                |
| 配信方法           | CloudFront OAC 経由         |

## Security

### セキュリティグループ

| SG 名              | インバウンド許可            | ソース                      |
| ------------------ | --------------------------- | --------------------------- |
| `web_security`     | 80, 443, 22                 | `0.0.0.0/0`                 |
| `api_security`     | 80                          | ALB SG のみ                 |
| `db_security`      | 3306                        | API SG のみ                 |

### IAM グループ・ポリシー

| グループ名                  | 権限                                    | メンバー例            |
| --------------------------- | --------------------------------------- | --------------------- |
| `server-management-group`   | EC2 開始/停止/再起動/削除               | jiro.test, shiro.test |
| `database-management-group` | RDS 開始/停止/再起動/スナップショット   | saburo.test           |
| `user-management-group`     | IAM ユーザー作成/削除/更新              | taro.test             |

## CI/CD Pipeline

### パイプライン構成 (cicd.tf)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Source    │───►│    Build    │───►│   Deploy    │
│   (GitHub)  │    │ (CodeBuild) │    │(CodeDeploy) │
└─────────────┘    └─────────────┘    └─────────────┘
       │                  │                  │
       ▼                  ▼                  ▼
  CodeStar         Docker Build         Blue-Green
  Connection       ECR Push             ECS Deploy
```

### CodeBuild 設定

| 設定項目           | 値                          |
| ------------------ | --------------------------- |
| プロジェクト名     | `api-build`                 |
| イメージ           | `aws/codebuild/standard:5.0`|
| コンピュート       | BUILD_GENERAL1_SMALL        |
| 特権モード         | 有効 (Docker ビルド用)      |

### CodeDeploy 設定

| 設定項目           | 値                          |
| ------------------ | --------------------------- |
| アプリケーション名 | `api-deploy`                |
| デプロイグループ   | `api-deploy-group`          |
| デプロイ方式       | Blue-Green                  |
| 本番リスナー       | HTTPS:443                   |
| テストリスナー     | HTTPS:8080                  |
| 旧環境終了         | デプロイ成功後 5 分         |
| 自動ロールバック   | デプロイ失敗時              |

### Lambda (デプロイフック)

- 関数名: `sprints-deployment-hook`
- ランタイム: Python 3.9
- 用途: CodeDeploy ライフサイクルイベントの検証

## File Structure

```
terraform/
├── main.tf                  # プロバイダー定義、ローカル変数
├── variables.tf             # 入力変数定義
├── network.tf               # VPC、サブネット、ルートテーブル、NAT GW
├── compute.tf               # ECS、セキュリティグループ、IAM ロール
├── alb.tf                   # ALB、ターゲットグループ、リスナー
├── rds.tf                   # RDS インスタンス、パラメータグループ
├── s3.tf                    # S3 バケット、OAC、バケットポリシー
├── ecr.tf                   # ECR リポジトリ
├── cicd.tf                  # CodePipeline、CodeBuild、CodeDeploy
├── cloudfront-acm.tf        # CloudFront Distribution、ACM 参照
├── route53.tf               # Route53 ホストゾーン、エイリアスレコード
├── IAM.tf                   # IAM ユーザー、グループ、ポリシー
├── lambda.tf                # デプロイフック Lambda
├── ec2_instance_connect.tf  # EC2 Instance Connect Endpoint
└── terraform.tfvars         # 環境固有の変数値 (.gitignore)
```

## Outputs

| 出力名               | 説明                        | 定義ファイル  |
| -------------------- | --------------------------- | ------------- |
| `alb_dns_name`       | ALB の DNS 名               | alb.tf        |
| `ecr_repository_url` | ECR リポジトリ URL          | ecr.tf        |

---

## Sprint Notes

<details>
<summary><strong>Sprint6: DevOps (CI/CD Pipeline)</strong></summary>

#### Points

- **リポジトリの責務分離**
  インフラ (`terraform/`) とアプリ (`cloudtech-reservation-api/`) のリポジトリを分けることで、アプリ開発者がインフラを意識せずにデプロイできる構成に。

- **環境変数の注入**
  ECR のリポジトリ URL など、Terraform で作成される動的な値を `aws_codebuild_project` の `environment_variable` を通じて `buildspec.yml` に渡す。

- **Blue/Green Deployment**
  - Terraform で Blue/Green を実装する場合、appspec.yml や taskdef.json の動的生成が必要
  - DockerHub からの Ratelimit 対策として、AWS の公式リポジトリを利用

</details>

<details>
<summary><strong>Sprint5: Container (ECS/Fargate)</strong></summary>

#### Problem/Resolution

- ECS サービス作成エラー (InvalidParameterException)
  ALB と ECS サービスの間に循環依存 (`depends_on`) が発生し、ターゲットグループが ALB に紐付く前に ECS サービスが作成されようとしたためエラー。`alb.tf` の `depends_on` を削除し、逆に `compute.tf` の ECS サービス側で `depends_on = [aws_lb_listener...]` を設定して解決
- CORS エラー (No 'Access-Control-Allow-Origin')
  パブリックイメージ (`public.ecr.aws`) には CORS 対応が含まれていなかったため発生。ローカルの Go コード（CORS 対応済み）をビルドし、自身の ECR リポジトリ (`sprints-api`) に Push して解決
- ポート不整合
  環境変数 `API_PORT=80` に対し、タスク定義や ALB が `8080` を向いていたため通信不可。全て `80` に統一して解決
- タスク定義が更新されない (非アクティブのまま)
  `lifecycle { ignore_changes = [task_definition] }` が設定されていたため、新しいイメージを指定しても ECS サービスが古いタスク定義を使い続けていた。設定を削除して解決
- DB 初期化
  Fargate 化に伴い `user_data` が実行されなくなるため、DB 初期化（テーブル作成）が行われない問題が発生。
  **解決策:** Go アプリケーション (`main.go`) に起動時に DB とテーブルを自動作成する処理 (`initDB`) を追加し、インフラに依存せずアプリ側で完結するように修正。
- ヘルスチェック失敗 (Unhealthy)
  アプリは起動しているが ALB からのヘルスチェックがタイムアウトする現象が発生。
  一時的に VPC 全開放 (`0.0.0.0/0`) や VPC 内限定 (`cidr_blocks`) で切り分けを行ったが、最終的にはセキュリティ要件を満たすため **ALB のセキュリティグループ参照 (`source_security_group_id`)** に戻して動作確認はしていない。
- 不要なポート開放の削除
  Fargate 化に伴い SSH 接続（ポート 22）は不要となるため、セキュリティグループのインバウンドルールから削除。

</details>

<details>
<summary><strong>Sprint4: Contents Delivery (CloudFront/Route53)</strong></summary>

#### Problem/Resolution

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

</details>

<details>
<summary><strong>Sprint3: Redundancy (ALB/Auto Scaling)</strong></summary>

#### Problem/Resolution

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

</details>

<details>
<summary><strong>Sprint2: RDS and Authentication</strong></summary>

#### Problem/Resolution

- サーバ作成順（depends_on）
- 変数利用（variables.tf,terraform.tfvars）
- user_data.sh の失敗で停止(set -euo pipefail)
- user_data.sh のパッケージインストール失敗を保険(for,if,etc)
- user_data.sh で DB 接続を確認して後続処理を走らせる(until)
- user_data.sh で特定 PID を変数にして kill する処理
- user_data.sh の処理待ちの確認(EC2: Actions-"Monitor and troubleshoot"-"Get system log")

</details>

<details>
<summary><strong>Sprint1: Network and Servers</strong></summary>

#### Problem/Resolution

- 要件: Web アプリケーション起動および"API Test"の正常動作
- 結果:
  - Terraform で構成作成
  - user_data.sh.tmpl を使って自動化
    - スクリプト作成
    - 値の渡し方(templatefile,ヒアドキュメント)

</details>
