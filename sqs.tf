module "sqs_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self

  attributes = []
}

locals {
  sqs_queue_name = var.sqs_queue_name != null ? var.sqs_queue_name : "${module.eventbridge_rule_context.id}-dlq"
}
resource "aws_sqs_queue" "dead_letter_queue" {
  count                      = module.sfn_error_notification_context.enabled ? 1 : 0
  name                       = local.sqs_queue_name
  message_retention_seconds  = var.sqs_message_retention_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds

  kms_master_key_id = var.sqs_kms_key_id
  tags              = module.sfn_error_notification_context.tags
}
