# ──────────────────────────────────────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "upload_url" {
  description = "Full URL for uploading images"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/upload"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.images.id
}

output "sqs_queue_url" {
  description = "URL of the main SQS queue"
  value       = aws_sqs_queue.image_queue.url
}

output "sqs_dlq_url" {
  description = "URL of the dead-letter queue"
  value       = aws_sqs_queue.image_dlq.url
}

output "upload_lambda_name" {
  description = "Name of the upload Lambda function"
  value       = aws_lambda_function.upload.function_name
}

output "crop_lambda_name" {
  description = "Name of the crop Lambda function"
  value       = aws_lambda_function.crop.function_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}
