# ──────────────────────────────────────────────────────────────────────────────
# Security Groups
# ──────────────────────────────────────────────────────────────────────────────

# SG for the Upload Lambda
resource "aws_security_group" "upload_lambda" {
  name        = "${local.name_prefix}-sg-upload-lambda"
  description = "Security group for Upload Lambda - outbound only to VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # Outbound: HTTPS to S3 Gateway and SQS Interface endpoints
  egress {
    description = "HTTPS to VPC endpoints and AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-upload-lambda"
  }
}

# SG for the Crop Lambda
resource "aws_security_group" "crop_lambda" {
  name        = "${local.name_prefix}-sg-crop-lambda"
  description = "Security group for Crop Lambda - outbound only to VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # Outbound: HTTPS to S3 Gateway and SQS Interface endpoints
  egress {
    description = "HTTPS to VPC endpoints and AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-crop-lambda"
  }
}

# SG for the SQS VPC Endpoint
resource "aws_security_group" "vpce_sqs" {
  name        = "${local.name_prefix}-sg-vpce-sqs"
  description = "Security group for SQS VPC Interface Endpoint"
  vpc_id      = aws_vpc.main.id

  # Inbound: HTTPS from Upload Lambda
  ingress {
    description     = "HTTPS from Upload Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.upload_lambda.id]
  }

  # Inbound: HTTPS from Crop Lambda
  ingress {
    description     = "HTTPS from Crop Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.crop_lambda.id]
  }

  tags = {
    Name = "${local.name_prefix}-sg-vpce-sqs"
  }
}
