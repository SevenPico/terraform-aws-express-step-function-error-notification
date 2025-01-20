module "eventbridge_rule_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.sfn_error_notification_context.self
}

locals {
  eventbridge_rule_name = var.eventbridge_rule_name != null ? var.eventbridge_rule_name : "${module.eventbridge_rule_context.id}-err-rule"
}

resource "aws_cloudwatch_event_rule" "eventbridge_rule" {
  count       = module.sfn_error_notification_context.enabled ? 1 : 0
  name        = local.eventbridge_rule_name
  description = "Eventbridge rule to route failure events to sqs."
  event_pattern = jsonencode({
    "source" : ["7π.states"],
    "detail-type" : ["Express Step Functions Execution Status Change"],
    "detail" : {
      "status" : ["ExecutionFailed"],
      "execution_arn" : [{
        "prefix" : "${split(":stateMachine:", var.state_machine_arn)[0]}:express:${split(":stateMachine:", var.state_machine_arn)[1]}:"
      }]
    }
  })
}

resource "aws_cloudwatch_event_target" "eventbridge_target" {
  count     = module.sfn_error_notification_context.enabled ? 1 : 0
  rule      = try(aws_cloudwatch_event_rule.eventbridge_rule[0].name, "")
  target_id = "send-failed-to-dlq"
  arn       = try(aws_sqs_queue.dead_letter_queue[0].arn, "")
}

# rather than using a role attached to the target, we use an SQS queue policy to allow the eventbridge rule to send messages to the queue

resource "aws_sqs_queue_policy" "analytics_cloudwatch_event_queue_policy" {
  count     = module.sfn_error_notification_context.enabled ? 1 : 0
  queue_url = replace(aws_sqs_queue.dead_letter_queue[0].arn, "arn:aws:sqs:${local.region}:${local.account_id}:", "https://sqs.${local.region}.amazonaws.com/${local.account_id}/")
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
            "aws:SourceArn" : aws_cloudwatch_event_rule.eventbridge_rule[0].arn
          }
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.dead_letter_queue[0].arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "step_function_monitor" {
  count       = module.sfn_error_notification_context.enabled ? 1 : 0