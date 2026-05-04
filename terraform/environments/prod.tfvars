# ──────────────────────────────────────────────────────────────────────────────
# PROD Environment Configuration
# ──────────────────────────────────────────────────────────────────────────────

environment = "prod"
aws_region  = "us-east-1"

# VPC CIDR
vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24"]

# Full resources for production (as specified in architecture)
upload_lambda_memory  = 256
upload_lambda_timeout = 30
crop_lambda_memory    = 512
crop_lambda_timeout   = 60

# Full retention for production
s3_uploads_expiration_days   = 30
s3_processed_expiration_days = 90
log_retention_days           = 14

# Full throttle for production
api_throttle_rate  = 10000
api_throttle_burst = 5000

sqs_batch_size = 5
