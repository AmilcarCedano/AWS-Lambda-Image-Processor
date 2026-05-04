# ──────────────────────────────────────────────────────────────────────────────
# S3 Bucket — Image Storage
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "images" {
  bucket = "${local.name_prefix}-images-${data.aws_caller_identity.current.account_id}"

  # Prevent accidental deletion in prod
  force_destroy = var.environment != "prod"

  tags = {
    Name = "${local.name_prefix}-images"
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = var.s3_uploads_expiration_days
    }
  }

  rule {
    id     = "expire-processed"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    expiration {
      days = var.s3_processed_expiration_days
    }
  }
}

# S3 Event Notification → SQS (on ObjectCreated in uploads/)
resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn     = aws_sqs_queue.image_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }

  depends_on = [aws_sqs_queue_policy.allow_s3]
}
