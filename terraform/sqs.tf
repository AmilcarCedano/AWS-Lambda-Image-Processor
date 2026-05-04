# ──────────────────────────────────────────────────────────────────────────────
# SQS — Message Queuing
# ──────────────────────────────────────────────────────────────────────────────

# Dead-Letter Queue
resource "aws_sqs_queue" "image_dlq" {
  name                      = "${local.name_prefix}-image-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "${local.name_prefix}-image-dlq"
  }
}

# Main Queue
resource "aws_sqs_queue" "image_queue" {
  name                       = "${local.name_prefix}-image-queue"
  visibility_timeout_seconds = var.sqs_visibility_timeout
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 20    # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.image_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = {
    Name = "${local.name_prefix}-image-queue"
  }
}

# SQS Policy — Allow S3 to send messages
resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.image_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3SendMessage"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.image_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.images.arn
          }
        }
      }
    ]
  })
}
