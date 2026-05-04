# ──────────────────────────────────────────────────────────────────────────────
# CloudWatch — Observability
# ──────────────────────────────────────────────────────────────────────────────

# Log Groups
resource "aws_cloudwatch_log_group" "upload_lambda" {
  name              = "/aws/lambda/${local.name_prefix}-upload"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "crop_lambda" {
  name              = "/aws/lambda/${local.name_prefix}-crop"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${local.name_prefix}-api"
  retention_in_days = var.log_retention_days
}

# SNS Topic for alarms
resource "aws_sns_topic" "alarms" {
  name = "${local.name_prefix}-alarms"
}

# CloudWatch Alarm: DLQ messages
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${local.name_prefix}-dlq-messages-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when messages appear in the Dead-Letter Queue"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.image_dlq.name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}
