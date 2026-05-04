# ──────────────────────────────────────────────────────────────────────────────
# DEV Environment Configuration
# Region: us-east-1 (N. Virginia)
# ──────────────────────────────────────────────────────────────────────────────

environment = "dev"
aws_region  = "us-east-1"

# VPC CIDR — unique per environment to avoid conflicts
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# Smaller resources for dev
upload_lambda_memory  = 256
upload_lambda_timeout = 30
crop_lambda_memory    = 512
crop_lambda_timeout   = 60

# Shorter retention for dev
s3_uploads_expiration_days   = 7
s3_processed_expiration_days = 14
log_retention_days           = 7

# Lower throttle for dev
api_throttle_rate  = 1000
api_throttle_burst = 500

sqs_batch_size = 5
