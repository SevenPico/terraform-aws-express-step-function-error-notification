module "example_rate_sns_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.example_context.enabled
  attributes = ["example", "rate", "sns"]
}

module "example_volume_sns_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.example_context.enabled
  attributes = ["example", "volume", "sns"]
}

module "rate_alarm_alert_sns" {
  count   = module.example_rate_sns_context.enabled ? 1 : 0
  source  = "SevenPico/sns/aws"
  version = "2.0.2"
  context = module.example_rate_sns_context.self

  pub_principals    = {}
  sub_principals    = {}
}

module "volume_alarm_alert_sns" {
  count   = module.example_volume_sns_context.enabled ? 1 : 0
  source  = "SevenPico/sns/aws"
  version = "2.0.2"
  context = module.example_volume_sns_context.self

  pub_principals    = {}
  sub_principals    = {}
}
