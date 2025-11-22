# ---------------------------------
# 変数定義
# ---------------------------------
locals {
  bucket_name = "sprints-iimura-s3-bucket-20251122"
}

# ---------------------------------
# 1. S3 バケット作成
# ---------------------------------
resource "aws_s3_bucket" "sprints_static_site" {
  bucket        = local.bucket_name
  force_destroy = true
}

# ---------------------------------
# 2. パブリックアクセスブロックの設定
# ---------------------------------
resource "aws_s3_bucket_public_access_block" "sprints_static_site" {
  bucket = aws_s3_bucket.sprints_static_site.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------
# 2.1 CloudFront Origin Access (OAC)
# ---------------------------------
resource "aws_cloudfront_origin_access_control" "sprints_static_site" {
  name                              = "${local.bucket_name}-oac"
  description                       = "OAC for ${local.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# # ---------------------------------
# # 3. 静的ウェブホスティングの設定
# # ---------------------------------
# resource "aws_s3_bucket_website_configuration" "sprints_static_site" {
#   bucket = aws_s3_bucket.sprints_static_site.bucket
#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "error.html"
#   }
# }

# ---------------------------------
# 4. バケットポリシーの設定
# ---------------------------------
resource "aws_s3_bucket_policy" "sprints_static_site" {
  bucket     = aws_s3_bucket.sprints_static_site.bucket
  depends_on = [aws_s3_bucket_public_access_block.sprints_static_site]

  # OACを介したCloudFrontからのアクセスのみを許可するポリシー
  policy = data.aws_iam_policy_document.sprints_s3_access_policy.json
}

# S3アクセス許可のためのIAMポリシードキュメントをデータソースとして定義
data "aws_iam_policy_document" "sprints_s3_access_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    # CloudFrontプリンシパルを指定
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.sprints_static_site.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        "${aws_cloudfront_distribution.sprints_s3_distribution.arn}"
      ]
    }
  }
}

# ---------------------------------------------
# 5. GitHubからCloneしてS3にSync
# ---------------------------------------------
resource "null_resource" "sprints_git_clone_and_sync" {
  triggers = {
    # リポジトリURLが変わったら再実行
    repo_url = var.github_repo_url
    # 毎回実行してconfig.jsを更新する
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      # 一時ディレクトリの定義
      TMP_DIR="${path.module}/.tmp_content"
      
      # クリーンアップ（前の残骸があれば消す）
      rm -rf $TMP_DIR
      
      # GitHubからClone
      git clone ${var.github_repo_url} $TMP_DIR
      
      # config.js を作成/上書きしてAPIの向き先を変更
      # 注意: var.domain_name は terraform apply 時に展開されます
cat > $TMP_DIR/config.js <<CONFIG
var apiConfig = {
  baseURL: "https://api.${var.domain_name}"
};
CONFIG
      
      # S3にSync（.gitディレクトリは除外）
      aws s3 sync $TMP_DIR s3://${aws_s3_bucket.sprints_static_site.bucket} --exclude ".git/*" --delete
      
      # クリーンアップ
      rm -rf $TMP_DIR
    EOT
  }
}
