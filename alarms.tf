resource "aws_cloudwatch_metric_alarm" "rate_alarm" {
  count             = module.sfn_error_notification_context.enabled ? 1 : 0
  depends_on        = [var.rate_sns_topic_arn]
  alarm_name        = var.rate_alarm_name != null ? var.rate_alarm_name : "${module.sfn_error_notification_context.id}-rate"
  alarm_description = "ALARM when the rate of growth for the ${module.sfn_error_notification_context.id} Dead Letter Queue exceeds the threshold"

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
        QueueName = module.sfn_error_notification_context.id
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
  tags                = module.sfn_error_notification_context.tags
}

resource "aws_cloudwatch_metric_alarm" "volume_alarm" {
  count      = module.sfn_error_notification_context.enabled ? 1 : 0
  depends_on = [var.volume_sns_topic_arn]

  alarm_name          = var.volume_alarm_name != null ? var.volume_alarm_name : "${module.sfn_error_notification_context.id}-volume"
  alarm_description   = "ALARM when the ${module.sfn_error_notification_context.id} Dead Letter Queue has messages remaining to reprocess"
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
    QueueName = module.sfn_error_notification_context.id
  }
  alarm_actions = [var.volume_sns_topic_arn]
  ok_actions    = [var.volume_sns_topic_arn]
  tags          = module.sfn_error_notification_context.tags
}
