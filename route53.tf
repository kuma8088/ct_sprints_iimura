# ホストゾーンの作成
resource "aws_route53_zone" "sprints_zone" {
  name = "onamae-cloudtech-demo-2025.com"
}

# CloufFrontを向いたaliasレコード
resource "aws_route53_record" "sprints_alias_cloudfront" {
  zone_id = aws_route53_zone.sprints_zone.id
  name    = "www.onamae-cloudtech-demo-2025.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.sprints_s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.sprints_s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
