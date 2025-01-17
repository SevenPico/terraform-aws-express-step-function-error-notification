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
    "source" : ["aws.states"],
    "detail-type" : ["Step Functions Execution Status Change"],
    "detail" : {
      "status" : ["FAILED"],
      "stateMachineArn" : [var.state_machine_arn]
    }
  })
}

resource "aws_cloudwatch_event_target" "eventbridge_target" {
  count     = module.sfn_error_notification_context.enabled ? 1 : 0
  rule      = try(aws_cloudwatch_event_rule.eventbridge_rule[0].name, "")
  target_id = "send-to-sqs"
  arn       = try(aws_sqs_queue.dead_letter_queue[0].arn, "")
}
