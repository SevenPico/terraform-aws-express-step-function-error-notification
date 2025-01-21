module "step_function" {
  source     = "git::https://github.com/SevenPico/terraform-aws-step-functions.git?ref=hotfix/1.0.2"
  for_each   = local.step_functions
  context    = module.example_context.self
  attributes = [each.value.name, "sfn"]

  definition = {
    StartAt : "PassState",
    States : {
      PassState : {
        Type : "Pass",
        Next : "Fail"
      }
      Fail : {
        Type : "Fail"
      }
    }
  }
  cloudwatch_log_group_kms_key_id        = null
  cloudwatch_log_group_name              = "/aws/vendedlogs/states/${module.example_context.id}-${each.value.name}"
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_retention_days

  logging_configuration = {
    include_execution_data = true,
    level                  = "ALL"
  }
  policy_document_count     = 1
  policy_documents          = try([data.aws_iam_policy_document.example_step_function_policy_document[0].json], [])
  role_description          = "Example Step Function Permission role"
  role_path                 = "/"
  role_permissions_boundary = null
  step_function_name        = "${module.example_context.id}-${each.value.name}"
  tracing_enabled           = false
  type                      = "EXPRESS"
  tags                      = module.example_context.tags
  use_fullname              = true
}

data "aws_iam_policy_document" "example_step_function_policy_document" {
  count = module.example_context.enabled ? 1 : 0
  statement {
    sid = "AllowStepFunctionLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

output "state_machine_arn" {
  value = {
    for id, sfn in module.step_function : id => sfn.state_machine_arn
  }
}
