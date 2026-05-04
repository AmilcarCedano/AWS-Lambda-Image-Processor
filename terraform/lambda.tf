# ──────────────────────────────────────────────────────────────────────────────
# Lambda Functions — Docker Container Image Mode
# ──────────────────────────────────────────────────────────────────────────────

# ── Upload Lambda Function ──────────────────────────────────────────────────

resource "aws_lambda_function" "upload" {
  function_name = "${local.name_prefix}-upload"
  description   = "Handles image uploads via API Gateway, stores in S3 [${var.environment}]"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.upload_lambda.repository_url}:latest"

  memory_size = var.upload_lambda_memory
  timeout     = var.upload_lambda_timeout

  role = aws_iam_role.upload_lambda.arn

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.id
      UPLOAD_PREFIX = "uploads/"
      ENVIRONMENT   = var.environment
      AWS_REGION_DEPLOY = var.aws_region
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.upload_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.upload_basic,
    aws_iam_role_policy_attachment.upload_vpc,
    aws_cloudwatch_log_group.upload_lambda,
    null_resource.upload_lambda_docker,
  ]

  tags = {
    Name = "${local.name_prefix}-upload"
  }
}

# ── Crop Lambda Function ────────────────────────────────────────────────────

resource "aws_lambda_function" "crop" {
  function_name = "${local.name_prefix}-crop"
  description   = "Processes images: resize to 40x40 circular PNG [${var.environment}]"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.crop_lambda.repository_url}:latest"

  memory_size = var.crop_lambda_memory
  timeout     = var.crop_lambda_timeout

  role = aws_iam_role.crop_lambda.arn

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.id
      PROCESSED_PREFIX = "processed/"
      ENVIRONMENT      = var.environment
      AWS_REGION_DEPLOY = var.aws_region
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.crop_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.crop_basic,
    aws_iam_role_policy_attachment.crop_vpc,
    aws_cloudwatch_log_group.crop_lambda,
    null_resource.crop_lambda_docker,
  ]

  tags = {
    Name = "${local.name_prefix}-crop"
  }
}

# ── SQS Event Source Mapping (SQS → Crop Lambda) ────────────────────────────

resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn                   = aws_sqs_queue.image_queue.arn
  function_name                      = aws_lambda_function.crop.arn
  batch_size                         = var.sqs_batch_size
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 0
  enabled                            = true
}
