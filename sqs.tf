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
  kms_master_key_id          = var.sqs_kms_key_id
  tags                       = module.sfn_error_notification_context.tags
}
