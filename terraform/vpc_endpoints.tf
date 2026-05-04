# ──────────────────────────────────────────────────────────────────────────────
# VPC Endpoints — Traffic stays on AWS backbone
# ──────────────────────────────────────────────────────────────────────────────

# S3 Gateway Endpoint (free, no ENI)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.private[*].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Access"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.images.arn,
          "${aws_s3_bucket.images.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}

# SQS Interface Endpoint (ENI per AZ)
resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type = "Interface"

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpce_sqs.id]

  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-sqs"
  }
}
