module "sfn_error_notification_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
}

locals {
  step_functions = {
    for id, sfn in var.step_functions : id => {
      arn            = sfn.arn
      name           = local.enabled ? split(":stateMachine:", sfn.arn)[1] : ""
      log_group_name = local.enabled ? sfn.log_group_name : "/aws/vendedlogs/states/${split(":stateMachine:", sfn.arn)[1]}"
      sqs_queue_name = local.enabled ? "${split(":stateMachine:", sfn.arn)[1]}-dlq" : ""
    }
  }
}
