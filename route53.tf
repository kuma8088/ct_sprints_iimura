# ホストゾーンを参照する
data "aws_route53_zone" "sprints_zone" {
  name = var.domain_name
}

# CloufFrontを向いたaliasレコード
# resource "aws_route53_record" "sprints_alias_cloudfront_www" {
#   zone_id = data.aws_route53_zone.sprints_zone.zone_id
#   name    = "www.${var.domain_name}"
#   type    = "A"
#   alias {
#     name                   = aws_cloudfront_distribution.sprints_s3_distribution.domain_name
#     zone_id                = aws_cloudfront_distribution.sprints_s3_distribution.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

resource "aws_route53_record" "sprints_alias_cloudfront_apex" {
  zone_id = data.aws_route53_zone.sprints_zone.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.sprints_s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.sprints_s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
