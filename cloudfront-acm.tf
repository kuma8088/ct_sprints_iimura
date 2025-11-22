resource "aws_cloudfront_distribution" "sprints_s3_distribution" {
  enabled = true

  # ルートアクセス時のデフォルトファイル
  default_root_object = "index.html"

  # Originの設定
  origin {
    domain_name = aws_s3_bucket.sprints_static_site.bucket_regional_domain_name
    origin_id   = "s3-origin"

    # OACを設定
    origin_access_control_id = aws_cloudfront_origin_access_control.sprints_static_site.id
  }

  # キャッシュ動作
  default_cache_behavior {
    target_origin_id = "s3-origin"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    # HTTPSのみ許可し、HTTPは自動的にリダイレクトする
    viewer_protocol_policy = "redirect-to-https"

    # デフォルトのTTL設定
    cache_policy_id = "658327ea-f89d-4804-ac5d-f3ca777a0300" # Managed-CachingOptimized
  }

  # 地理的制限（なし）
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # HTTPS証明書の設定
  viewer_certificate {
    # 既存の証明書を使用
    acm_certificate_arn      = data.aws_acm_certificate.sprints_cf_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# ----------------------------------------------
# ACM証明書の取得(既存を参照)
# ----------------------------------------------

data "aws_acm_certificate" "sprints_cf_cert" {
  provider = aws.us_east_1

  domain      = "onamae-cloudtech-demo-2025.com"
  statuses    = ["ISSUED"]
  most_recent = true
}
