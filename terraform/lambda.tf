# ──────────────────────────────────────────────────────────────────────────────
# Lambda Functions — ZIP Package Mode
# ──────────────────────────────────────────────────────────────────────────────

# Build: install deps for upload Lambda
resource "null_resource" "upload_lambda_deps" {
  provisioner "local-exec" {
    command     = "npm install --omit=dev"
    working_dir = "${path.module}/../lambdas/upload"
  }
  triggers = {
    package_json = filemd5("${path.module}/../lambdas/upload/package.json")
  }
}

# Build: install deps for crop Lambda
resource "null_resource" "crop_lambda_deps" {
  provisioner "local-exec" {
    command     = "npm install --omit=dev"
    working_dir = "${path.module}/../lambdas/crop"
  }
  triggers = {
    package_json = filemd5("${path.module}/../lambdas/crop/package.json")
  }
}

# Package upload Lambda
data "archive_file" "upload_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/upload"
  output_path = "${path.module}/../.build/upload-lambda.zip"
  excludes    = ["Dockerfile"]
  depends_on  = [null_resource.upload_lambda_deps]
}

# Package crop Lambda
data "archive_file" "crop_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/crop"
  output_path = "${path.module}/../.build/crop-lambda.zip"
  excludes    = ["Dockerfile"]
  depends_on  = [null_resource.crop_lambda_deps]
}

# ── Upload Lambda Function ──────────────────────────────────────────────────

resource "aws_lambda_function" "upload" {
  function_name = "${local.name_prefix}-upload"
  description   = "Handles image uploads via API Gateway [${var.environment}]"

  filename         = data.archive_file.upload_lambda.output_path
  source_code_hash = data.archive_file.upload_lambda.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs20.x"

  memory_size = var.upload_lambda_memory
  timeout     = var.upload_lambda_timeout
  role        = aws_iam_role.upload_lambda.arn

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.id
      UPLOAD_PREFIX = "uploads/"
      ENVIRONMENT   = var.environment
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
  ]
}

# ── Crop Lambda Function ────────────────────────────────────────────────────

resource "aws_lambda_function" "crop" {
  function_name = "${local.name_prefix}-crop"
  description   = "Processes images: 40x40 circular PNG [${var.environment}]"

  filename         = data.archive_file.crop_lambda.output_path
  source_code_hash = data.archive_file.crop_lambda.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs20.x"

  memory_size = var.crop_lambda_memory
  timeout     = var.crop_lambda_timeout
  role        = aws_iam_role.crop_lambda.arn

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.id
      PROCESSED_PREFIX = "processed/"
      ENVIRONMENT      = var.environment
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
  ]
}

# ── SQS Event Source Mapping ────────────────────────────────────────────────

resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn                   = aws_sqs_queue.image_queue.arn
  function_name                      = aws_lambda_function.crop.arn
  batch_size                         = var.sqs_batch_size
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 0
  enabled                            = true
}
