# Private ECR repositories for the two container images.
# CI (GitHub Actions, OIDC) pushes here; EKS nodes pull from here.

resource "aws_ecr_repository" "frontend" {
  name                 = "cloudmart-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "backend" {
  name                 = "cloudmart-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
