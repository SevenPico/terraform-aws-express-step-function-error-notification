module "sfn_error_notification_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
}

locals {
  step_functions = {
    for id, sfn in var.step_functions : id => {
      name           = split(":stateMachine:", sfn.arn)[1]
      arn            = sfn.arn
      sqs_queue_name = "${split(":stateMachine:", sfn.arn)[1]}-dlq"
    }
  }
}
