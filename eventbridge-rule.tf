module "eventbridge_rule_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.sfn_error_notification_context.self
}

locals {
  eventbridge_rules = {
    for id, sfn in var.step_functions : id => {
      name = "${split(":stateMachine:", sfn.arn)[1]}-err-rule"
      arn  = sfn.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "eventbridge_rule" {
  for_each    = module.sfn_error_notification_context.enabled ? local.eventbridge_rules : {}
  name        = each.value.name
  description = "Eventbridge rule to route failure events to sqs for ${split(":stateMachine:", each.value.arn)[1]}"

  event_pattern = jsonencode({
    "source" : ["7π.states"],
    "detail-type" : ["Express Step Functions Execution Status Change"],
    "detail" : {
      "type" : ["ExecutionFailed"],
      "execution_arn" : [{
        "prefix" : "${split(":stateMachine:", each.value.arn)[0]}:express:${split(":stateMachine:", each.value.arn)[1]}:"
      }]
    }
  })

  tags = merge(
    module.sfn_error_notification_context.tags,
    {
      Name = each.value.name
    }
  )
}

resource "aws_cloudwatch_event_target" "eventbridge_target" {
  for_each  = module.sfn_error_notification_context.enabled ? local.eventbridge_rules : {}
  rule      = aws_cloudwatch_event_rule.eventbridge_rule[each.key].name
  target_id = "send-failed-to-dlq"
  arn       = aws_sqs_queue.dead_letter_queue[each.key].arn
}

# rather than using a role attached to the target, we use an SQS queue policy to allow the eventbridge rule to send messages to the queue

resource "aws_sqs_queue_policy" "analytics_cloudwatch_event_queue_policy" {
  for_each  = module.sfn_error_notification_context.enabled ? var.step_functions : {}
  queue_url = aws_sqs_queue.dead_letter_queue[each.key].url

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : aws_cloudwatch_event_rule.eventbridge_rule[each.key].arn
          }
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.dead_letter_queue[each.key].arn
      }
    ]
  })
}
