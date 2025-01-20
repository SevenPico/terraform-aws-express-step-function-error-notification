module "example_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["example", "sfn"]
}

module "express_sfn_error_notifications" {
  source     = "../../"
  context    = module.example_context.self
  attributes = ["example", "sfn"]

  state_machine_arn    = module.example_step_function.state_machine_arn
  rate_sns_topic_arn   = module.example_sns.topic_arn
  volume_sns_topic_arn = module.example_sns.topic_arn
}


module "example_sns" {
  source     = "SevenPico/sns/aws"
  version    = "2.0.2"
  context    = module.example_context.self
  attributes = ["example", "sns"]

  pub_principals = {}
  sub_principals = {}
  tags           = module.example_context.tags
}
