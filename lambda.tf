module "lambda_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.sfn_error_notification_context.self
}

locals {
  lambda_name        = "xsf-log-to-eventbridge"
  step_function_name = try(split(":stateMachine:", var.step_function_arn)[1], "")
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
  count       = module.lambda_context.enabled ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambdas/xsf-log-to-eventbridge/index.mjs"
  output_path = "${path.module}/lambdas/xsf-log-to-eventbridge/index.zip"
}

module "xsf_log_to_eventbridge_lambda" {
  count   = module.lambda_context.enabled ? 1 : 0
  enabled = module.lambda_context.enabled
  source  = "registry.terraform.io/SevenPicoForks/lambda-function/aws"
  version = "2.0.3"

  function_name = local.lambda_name
  description   = "Forwards Express Step Functions logs it receives from CloudWatch Subscription Filter to EventBridge on the default event bus"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 128
  publish       = false

  # Update to use the zipped file
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

  tags = module.context.tags
}


# Reference to the Step Function log group
data "aws_cloudwatch_log_group" "step_function" {
  count = module.lambda_context.enabled ? 1 : 0
  name  = "/aws/vendedlogs/states/${local.step_function_name}"
}

# Add the standalone resource
resource "aws_cloudwatch_log_subscription_filter" "xsf_failures" {
  count           = module.lambda_context.enabled ? 1 : 0
  name            = "xsf-failures-to-eventbridge"
  log_group_name  = try(data.aws_cloudwatch_log_group.step_function[0].name, "")
  filter_pattern  = "{ $.type = \"ExecutionFailed\" }"
  destination_arn = try(module.xsf_log_to_eventbridge_lambda[0].arn, "")
}

# Add Lambda permission for CloudWatch Logs
resource "aws_lambda_permission" "cloudwatch_logs" {
  count         = module.lambda_context.enabled ? 1 : 0
  statement_id  = "CloudWatchLogsAllowLambdaInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = try(module.xsf_log_to_eventbridge_lambda[0].function_name, "")
  principal     = try("logs.${data.aws_region.current[0].name}.amazonaws.com", "")
  source_arn    = try("${data.aws_cloudwatch_log_group.step_function[0].arn}:*", "")
}
