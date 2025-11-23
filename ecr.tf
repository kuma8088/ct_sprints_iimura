resource "aws_ecr_repository" "sprints_api" {
  name                 = "sprints-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.sprints_api.repository_url
}
