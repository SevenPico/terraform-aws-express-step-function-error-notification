module "lambda_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.sfn_error_notification_context.self
}

locals {
  lambda_name = "${module.context.id}-xsf-log-to-eventbridge"
}

#------------------------------------------------------------------------------
# Lambda: Express Step Function Log to EventBridge
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "xsf_log_to_eventbridge_lambda_policy" {
  count = module.lambda_context.enabled ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["events:PutEvents"]
    resources = [
      "arn:aws:events:${data.aws_region.current[0].name}:${data.aws_caller_identity.current[0].account_id}:event-bus/default"
    ]
  }
}

# Add this data source to zip the file
data "archive_file" "lambda_zip" {
  count       = module.context.enabled ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambdas/xsf-log-to-eventbridge/index.mjs"
  output_path = "${path.module}/lambdas/xsf-log-to-eventbridge/index.zip"
}

module "xsf_log_to_eventbridge_lambda" {
  count   = module.context.enabled ? 1 : 0
  enabled = module.context.enabled
  source  = "registry.terraform.io/SevenPicoForks/lambda-function/aws"
  version = "2.0.3"

  function_name = local.lambda_name
  role_name     = "${local.lambda_name}-role"
  description   = "Forwards Express Step Functions logs it receives from CloudWatch Subscription Filter to EventBridge on the default event bus"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 128
  publish       = false

  filename         = data.archive_file.lambda_zip[0].output_path
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256

  lambda_environment = {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  lambda_role_source_policy_documents = [
    try(data.aws_iam_policy_document.xsf_log_to_eventbridge_lambda_policy[0].json, "")
  ]

  tags = merge(
    module.context.tags,
    {
      Name = local.lambda_name
    }
  )
}

# Add subscription filter for each Step Function
resource "aws_cloudwatch_log_subscription_filter" "xsf_failures" {
  for_each        = module.context.enabled ? local.step_functions : {}
  name            = "xsf-failures-to-eventbridge-${each.value.name}"
  log_group_name  = each.value.log_group_name
  filter_pattern  = "{ $.type = \"ExecutionFailed\" }"
  destination_arn = module.xsf_log_to_eventbridge_lambda[0].arn
}

# Update Lambda permission to allow all Step Function log groups
resource "aws_lambda_permission" "cloudwatch_logs" {
  for_each      = module.context.enabled ? local.step_functions : {}
  statement_id  = "CloudWatchLogsAllowLambdaInvokeFunction-${each.value.name}"
  action        = "lambda:InvokeFunction"
  function_name = module.xsf_log_to_eventbridge_lambda[0].function_name
  principal     = "logs.${data.aws_region.current[0].name}.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current[0].name}:${data.aws_caller_identity.current[0].account_id}:log-group:${each.value.log_group_name}:*"
}
