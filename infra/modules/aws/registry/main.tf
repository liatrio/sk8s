resource "aws_ecr_repository" "self" {
    name          = var.name
    force_delete  = true
    tags          = var.tags

    encryption_configuration {
      encryption_type = "AES256"
    }

    image_scanning_configuration {
      scan_on_push = true
    }

    image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "self" {
  repository = aws_ecr_repository.self.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
