# ──────────────────────────────────────────────────────────────────────────────
# QA Environment Configuration
# ──────────────────────────────────────────────────────────────────────────────

environment = "qa"
aws_region  = "us-east-1"

# VPC CIDR
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]

# Standard resources for QA
upload_lambda_memory  = 256
upload_lambda_timeout = 30
crop_lambda_memory    = 512
crop_lambda_timeout   = 60

# Standard retention for QA
s3_uploads_expiration_days   = 15
s3_processed_expiration_days = 30
log_retention_days           = 14

# Moderate throttle for QA
api_throttle_rate  = 5000
api_throttle_burst = 2500

sqs_batch_size = 5
