module "pipe_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.sfn_error_notification_context.self

  # hard-code enabled to false for now as a pending feature flag
  enabled    = false
  attributes = []
}

locals {
  pipes = {
    for id, sfn in var.step_functions : id => {
      name = local.enabled ? coalesce(
        var.eventbridge_pipe_name,
        "${module.pipe_context.id}-${split(":stateMachine:", sfn.arn)[1]}-err-pipe"
      ) : ""
      arn = sfn.arn
    }
  }
}

resource "aws_pipes_pipe" "pipe" {
  for_each = module.pipe_context.enabled ? local.pipes : {}

  name          = each.value.name
  role_arn      = try(module.pipe_role[each.key].arn, "")
  source        = aws_sqs_queue.dead_letter_queue[each.key].arn
  desired_state = "STOPPED"
  target        = each.value.arn

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
      log_group_arn = aws_cloudwatch_log_group.pipe_log_group[each.key].arn
    }
    level = var.eventbridge_pipe_log_level
  }
  tags = module.pipe_context.tags
}

data "aws_iam_policy_document" "pipe_policy_document" {
  for_each = module.pipe_context.enabled ? local.pipes : {}

  statement {
    sid = "SQSAccess"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes"
    ]
    resources = [aws_sqs_queue.dead_letter_queue[each.key].arn]
  }

  statement {
    sid       = "StepFunctionExecutionAccess"
    actions   = ["states:StartExecution"]
    resources = [each.value.arn]
  }

  statement {
    sid    = "PipeLoggingPermissions"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_cloudwatch_log_group.pipe_log_group[each.key].arn]
  }
}

module "pipe_role" {
  for_each   = module.pipe_context.enabled ? local.pipes : {}
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
        "${local.arn_prefix}:pipes:${local.region}:${local.account_id}:pipe/${each.value.name}"
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
  policy_documents     = [data.aws_iam_policy_document.pipe_policy_document[each.key].json]
  role_description     = "Role for EventBridge Pipe"
  use_fullname         = true
}

resource "aws_cloudwatch_log_group" "pipe_log_group" {
  for_each          = module.pipe_context.enabled ? local.pipes : {}
  name              = "/aws/vendedlogs/${each.value.name}-pipe-logs"
  retention_in_days = var.cloudwatch_log_retention_days
}
