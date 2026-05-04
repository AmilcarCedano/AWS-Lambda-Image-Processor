# ──────────────────────────────────────────────────────────────────────────────
# Variables
# ──────────────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod."
  }
}

variable "project_name" {
  description = "Base name for all resources"
  type        = string
  default     = "image-processor"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "upload_lambda_memory" {
  description = "Memory in MB for the upload Lambda"
  type        = number
  default     = 256
}

variable "upload_lambda_timeout" {
  description = "Timeout in seconds for the upload Lambda"
  type        = number
  default     = 30
}

variable "crop_lambda_memory" {
  description = "Memory in MB for the crop Lambda"
  type        = number
  default     = 512
}

variable "crop_lambda_timeout" {
  description = "Timeout in seconds for the crop Lambda"
  type        = number
  default     = 60
}

variable "sqs_visibility_timeout" {
  description = "SQS message visibility timeout in seconds (should be 6x crop Lambda timeout)"
  type        = number
  default     = 360
}

variable "sqs_max_receive_count" {
  description = "Max receives before message goes to DLQ"
  type        = number
  default     = 3
}

variable "s3_uploads_expiration_days" {
  description = "Days before uploads expire"
  type        = number
  default     = 30
}

variable "s3_processed_expiration_days" {
  description = "Days before processed images expire"
  type        = number
  default     = 90
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "api_throttle_rate" {
  description = "API Gateway throttle rate (requests per second)"
  type        = number
  default     = 10000
}

variable "api_throttle_burst" {
  description = "API Gateway throttle burst capacity"
  type        = number
  default     = 5000
}

variable "sqs_batch_size" {
  description = "SQS event source mapping batch size"
  type        = number
  default     = 5
}

# ──────────────────────────────────────────────────────────────────────────────
# Local values
# ──────────────────────────────────────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  azs         = ["${var.aws_region}a", "${var.aws_region}b"]
}
