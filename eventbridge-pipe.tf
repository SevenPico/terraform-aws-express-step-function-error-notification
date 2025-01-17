module "pipe_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.sfn_error_notification_context.self

  attributes = []
}

locals {
  eventbridge_pipe_name = var.eventbridge_pipe_name != null ? var.eventbridge_pipe_name : "${module.pipe_context.id}-err-pipe"
}

resource "aws_pipes_pipe" "pipe" {
  count = module.pipe_context.enabled ? 1 : 0

  name          = local.eventbridge_pipe_name
  role_arn      = try(module.pipe_role.arn, "")
  source        = try(aws_sqs_queue.dead_letter_queue[0].arn, "")
  desired_state = "STOPPED"
  target        = var.state_machine_arn

  source_parameters {
    sqs_queue_parameters {
      batch_size = var.eventbridge_pipe_batch_size
    }
  }
  target_parameters {
    input_template = var.target_step_function_input_template
    step_function_state_machine_parameters {
      invocation_type = "REQUEST_RESPONSE"
    }
  }
  log_configuration {
    cloudwatch_logs_log_destination {
      log_group_arn = try(aws_cloudwatch_log_group.pipe_log_group[0].arn, "")
    }
    level = var.eventbridge_pipe_log_level
  }
  tags = module.pipe_context.tags
}

data "aws_iam_policy_document" "pipe_policy_document" {
  count = module.pipe_context.enabled ? 1 : 0
  statement {
    sid = "SQSAccess"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes"
    ]
    resources = try([aws_sqs_queue.dead_letter_queue[0].arn], ["*"])
  }

  statement {
    sid       = "StepFunctionExecutionAccess"
    actions   = ["states:StartExecution"]
    resources = [var.state_machine_arn]
  }

  statement {
    sid    = "PipeLoggingPermissions"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_cloudwatch_log_group.pipe_log_group[0].arn]
  }
}

module "pipe_role" {
  source     = "registry.terraform.io/SevenPicoForks/iam-role/aws"
  version    = "2.0.2"
  context    = module.pipe_context.self
  attributes = var.eventbridge_pipe_name != null ? [] : ["err", "pipe"]

  assume_role_actions = ["sts:AssumeRole"]
  assume_role_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        "${local.arn_prefix}:pipes:${local.region}:${local.account_id}:pipe/${local.eventbridge_pipe_name}"
      ]
    },
    {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        local.account_id
      ]
    }
  ]

  principals = {
    Service : [
      "pipes.amazonaws.com",
    ]
  }
  managed_policy_arns = []

  max_session_duration = 3600
  path                 = "/"
  permissions_boundary = ""
  policy_description   = "Policy for EventBridge Pipe Role"
  policy_documents     = try([data.aws_iam_policy_document.pipe_policy_document[0].json], [])
  role_description     = "Role for EventBridge Pipe"
  use_fullname         = true
}

resource "aws_cloudwatch_log_group" "pipe_log_group" {
  count             = module.pipe_context.enabled ? 1 : 0
  name              = "/aws/vendedlogs/${local.eventbridge_pipe_name}-logs"
  retention_in_days = var.cloudwatch_log_retention_days
}
