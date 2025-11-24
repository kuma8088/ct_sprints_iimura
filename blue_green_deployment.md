# ECS Blue/Green Deployment Architecture

## 概要

本プロジェクトでは、AWS CodeDeploy を使用した ECS Fargate の Blue/Green デプロイメントを採用します。
これにより、新バージョン（Green）の稼働確認を行った上で、ダウンタイムなしに本番トラフィックを切り替えることが可能です。

## アーキテクチャ構成

### 1. ALB (Application Load Balancer)

Blue/Green デプロイを実現するために、ALB には 2 つのリスナーと 2 つのターゲットグループが必要です。

- **本番用リスナー (HTTPS: 443)**
  - **役割**: 一般ユーザー（CloudFront 経由）からのトラフィックを処理。
  - **接続先**: 現在稼働中のバージョン（Blue または Green）。
- **テスト用リスナー (HTTPS: 8080)**
  - **役割**: デプロイ中の新バージョンの動作確認用。CloudFront を経由せず直接アクセスする。
  - **接続先**: 次期バージョン（待機中の Green または Blue）。

### 2. ターゲットグループ

- **Target Group Blue**: 現在の本番環境（例）
- **Target Group Green**: 次期リリースの環境（例）
  ※ CodeDeploy がデプロイのたびに、この 2 つのターゲットグループを「本番用」と「テスト用」に入れ替えます。

### 3. CloudFront との関係

- CloudFront は常に **ALB の 443 ポート** をオリジンとして参照します。
- テスト用ポート（8080）は CloudFront を経由せず、開発者が直接 ALB の DNS 名に対してアクセスします。
- デプロイ完了（Swap）後、443 ポートの接続先が新バージョンに切り替わるため、CloudFront の設定変更は不要です。

## デプロイフロー (ECS Blue/Green with CodePipeline)

1.  **Build**: CodeBuild が新しい Docker イメージを作成し、ECR に Push。
    - 同時に `appspec.yaml` と `taskdef.json` を動的に生成します。
2.  **Deploy 開始**: CodePipeline が CodeDeploy をキック。
    - 生成されたアーティファクト（`appspec.yaml`, `taskdef.json`, `imagedefinitions.json`）を入力として使用します。
3.  **Green 環境起動**: CodeDeploy が新しいタスクセット（Green）を起動し、**テスト用リスナー (8080)** に紐付けます。
4.  **検証 (Validation)**:
    - **Lambda Lifecycle Hook**: `AfterAllowTestTraffic` フックで Lambda が起動し、自動テストや通知を実行。
    - **手動確認**: 開発者が `https://<ALB-DNS>:8080` にアクセスして動作確認。
5.  **トラフィック切り替え (Swap)**:
    - 検証 OK なら（または待機時間終了後）、CodeDeploy が **本番用リスナー (443)** の向き先を Green に切り替えます。
6.  **完了**: 旧環境（Blue）のタスクが停止されます。

## 必要なファイル

- **imagedefinitions.json**: コンテナ名とイメージ URI のマッピング。
- **appspec.yaml / taskdef.json**: CodePipeline の仕様上必要ですが、**`buildspec.yml` 内で動的に生成するため、リポジトリでの管理は不要** です。
