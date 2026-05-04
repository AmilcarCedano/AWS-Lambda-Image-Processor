# ──────────────────────────────────────────────────────────────────────────────
# ECR — Container Registries for Lambda Docker Images
# ──────────────────────────────────────────────────────────────────────────────

# ECR Repository for Upload Lambda
resource "aws_ecr_repository" "upload_lambda" {
  name                 = "${local.name_prefix}-upload"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.name_prefix}-upload-ecr"
  }
}

# ECR Repository for Crop Lambda
resource "aws_ecr_repository" "crop_lambda" {
  name                 = "${local.name_prefix}-crop"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.name_prefix}-crop-ecr"
  }
}

# Lifecycle policy — keep only last 5 images
resource "aws_ecr_lifecycle_policy" "upload_lambda" {
  repository = aws_ecr_repository.upload_lambda.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "crop_lambda" {
  repository = aws_ecr_repository.crop_lambda.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# Docker Build & Push — using null_resource + local-exec
# ──────────────────────────────────────────────────────────────────────────────

# Login to ECR
resource "null_resource" "ecr_login" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    aws_ecr_repository.upload_lambda,
    aws_ecr_repository.crop_lambda
  ]
}

# Build & Push Upload Lambda Image
resource "null_resource" "upload_lambda_docker" {
  provisioner "local-exec" {
    command     = <<-EOT
      docker build --platform linux/amd64 -t ${aws_ecr_repository.upload_lambda.repository_url}:latest .
      docker push ${aws_ecr_repository.upload_lambda.repository_url}:latest
    EOT
    working_dir = "${path.module}/../lambdas/upload"
  }

  triggers = {
    dockerfile   = filemd5("${path.module}/../lambdas/upload/Dockerfile")
    index_mjs    = filemd5("${path.module}/../lambdas/upload/index.mjs")
    package_json = filemd5("${path.module}/../lambdas/upload/package.json")
  }

  depends_on = [null_resource.ecr_login]
}

# Build & Push Crop Lambda Image
resource "null_resource" "crop_lambda_docker" {
  provisioner "local-exec" {
    command     = <<-EOT
      docker build --platform linux/amd64 -t ${aws_ecr_repository.crop_lambda.repository_url}:latest .
      docker push ${aws_ecr_repository.crop_lambda.repository_url}:latest
    EOT
    working_dir = "${path.module}/../lambdas/crop"
  }

  triggers = {
    dockerfile   = filemd5("${path.module}/../lambdas/crop/Dockerfile")
    index_mjs    = filemd5("${path.module}/../lambdas/crop/index.mjs")
    package_json = filemd5("${path.module}/../lambdas/crop/package.json")
  }

  depends_on = [null_resource.ecr_login]
}
