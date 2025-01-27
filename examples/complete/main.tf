module "example_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = [""]
  enabled    = module.context.enabled
}

locals {
  step_functions = {
    one = {
      name = "one"
    }
    two = {
      name = "two"
    }
    three = {
      name = "three"
    }
  }
}

module "express_sfn_error_notifications" {
  source     = "../../"
  context    = module.example_context.self
  attributes = [""]

  step_functions = module.context.enabled ? {
    for id, sfn in module.step_function : id => {
      arn            = sfn.state_machine_arn
      log_group_name = "/aws/vendedlogs/states/${split(":stateMachine:", sfn.state_machine_arn)[1]}"
    }
  } : {}

  rate_sns_topic_arn   = try(module.rate_alarm_alert_sns[0].topic_arn, "")
  volume_sns_topic_arn = try(module.volume_alarm_alert_sns[0].topic_arn, "")

  # KMS configuration for SQS
  sqs_kms_key_config = module.context.enabled ? {
    key_id  = aws_kms_key.sqs_kms_key[0].key_id
    key_arn = aws_kms_key.sqs_kms_key[0].arn
  } : null
}
