resource "aws_cloudwatch_metric_alarm" "rate_alarm" {
  for_each          = module.sfn_error_notification_context.enabled ? local.step_functions : {}
  depends_on        = [var.rate_sns_topic_arn]
  alarm_name        = "${each.value.name}-rate-alarm"
  alarm_description = "ALARM when the rate of growth for the ${each.value.name} Dead Letter Queue exceeds the threshold"

  metric_query {
    id          = "e1"
    expression  = "RATE(m1)"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      period      = var.alarms_period
      stat        = "Maximum"
      dimensions = {
        QueueName = each.value.sqs_queue_name
      }
    }
    return_data = false
  }

  evaluation_periods  = var.alarms_evaluation_periods
  datapoints_to_alarm = var.alarms_datapoints_to_alarm
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "ignore"
  alarm_actions       = [var.rate_sns_topic_arn]
  ok_actions          = [var.rate_sns_topic_arn]
  tags = merge(
    module.sfn_error_notification_context.tags,
    {
      Name = "${each.value.name}-dlq-rate-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "volume_alarm" {
  for_each   = module.sfn_error_notification_context.enabled ? local.step_functions : {}
  depends_on = [var.volume_sns_topic_arn]

  alarm_name          = "${each.value.name}-volume-alarm"
  alarm_description   = "ALARM when the ${each.value.name} Dead Letter Queue has messages remaining to reprocess"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  statistic           = "Maximum"
  period              = var.alarms_period
  evaluation_periods  = var.alarms_evaluation_periods
  datapoints_to_alarm = var.alarms_datapoints_to_alarm
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "ignore"
  dimensions = {
    QueueName = each.value.sqs_queue_name
  }
  alarm_actions = [var.volume_sns_topic_arn]
  ok_actions    = [var.volume_sns_topic_arn]
  tags = merge(
    module.sfn_error_notification_context.tags,
    {
      Name = "${each.value.name}-dlq-volume-alarm"
    }
  )
}

data "aws_iam_policy_document" "sns_publish_policy" {
  count = module.sfn_error_notification_context.enabled && var.sns_kms_key_config != null ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions = ["sns:Publish"]
    resources = [
      var.rate_sns_topic_arn,
      var.volume_sns_topic_arn
    ]
  }

  statement {
    sid    = "AllowKMSEncryption"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [var.sns_kms_key_config.key_arn]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:cloudwatch:${data.aws_region.current[0].name}:${data.aws_caller_identity.current[0].account_id}:alarm:*-rate-alarm",
        "arn:aws:cloudwatch:${data.aws_region.current[0].name}:${data.aws_caller_identity.current[0].account_id}:alarm:*-volume-alarm"
      ]
    }
  }
}

resource "aws_sns_topic_policy" "rate_alarm_policy" {
  count  = module.sfn_error_notification_context.enabled && var.sns_kms_key_config != null ? 1 : 0
  arn    = var.rate_sns_topic_arn
  policy = data.aws_iam_policy_document.sns_publish_policy[0].json
}

resource "aws_sns_topic_policy" "volume_alarm_policy" {
  count  = module.sfn_error_notification_context.enabled && var.sns_kms_key_config != null ? 1 : 0
  arn    = var.volume_sns_topic_arn
  policy = data.aws_iam_policy_document.sns_publish_policy[0].json
}

