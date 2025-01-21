module "example_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["example"]
  enabled    = module.context.enabled
}

module "express_sfn_error_notifications" {
  source     = "../../"
  context    = module.example_context.self
  attributes = ["example"]

  step_function_arn    = module.example_step_function.state_machine_arn
  rate_sns_topic_arn   = module.rate_alarm_alert_sns[0].topic_arn
  volume_sns_topic_arn = module.volume_alarm_alert_sns[0].topic_arn
}
