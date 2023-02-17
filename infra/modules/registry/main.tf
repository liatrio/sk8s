resource "aws_ecr_repository" "self" {
    name          = var.name
    force_delete  = true
    tags          = var.tags

    encryption_configuration {
      encryption_type = "AES256"
    }
}
