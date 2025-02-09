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
  count   = module.context.enabled ? 1 : 0
  source  = "SevenPico/sns/aws"
  version = "2.0.2"
  context = module.example_rate_sns_context.self

  pub_principals = {}
  sub_principals = {}

  kms_master_key_id = module.context.enabled ? aws_kms_key.sns_kms_key[0].id : null
}

module "volume_alarm_alert_sns" {
  count   = module.context.enabled ? 1 : 0
  source  = "SevenPico/sns/aws"
  version = "2.0.2"
  context = module.example_volume_sns_context.self

  pub_principals = {}
  sub_principals = {}

  kms_master_key_id = module.context.enabled ? aws_kms_key.sns_kms_key[0].id : null
}
