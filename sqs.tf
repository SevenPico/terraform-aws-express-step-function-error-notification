module "sqs_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
}

resource "aws_sqs_queue" "dead_letter_queue" {
  for_each                   = module.sfn_error_notification_context.enabled ? var.step_functions : {}
  name                       = local.step_functions[each.key].sqs_queue_name
  message_retention_seconds  = var.sqs_message_retention_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  kms_master_key_id          = try(var.kms_key_config.key_id, null)
  tags = merge(
    module.sfn_error_notification_context.tags,
    {
      Name = local.step_functions[each.key].sqs_queue_name
    }
  )
}


resource "aws_sqs_queue_policy" "queue_policy" {
  for_each  = module.sfn_error_notification_context.enabled ? var.step_functions : {}
  queue_url = aws_sqs_queue.dead_letter_queue[each.key].url

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.step_functions[each.key].sqs_queue_name}-policy"
    Statement = concat([
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.dead_letter_queue[each.key].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.eventbridge_rule[each.key].arn
          }
        }
      }],
      var.kms_key_config != null ? [{
        Sid    = "KmsPermissions"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_config.key_arn
      }] : []
    )
  })
}
