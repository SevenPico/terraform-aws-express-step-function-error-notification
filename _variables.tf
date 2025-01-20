variable "state_machine_arn" {
  description = "The ARN of the Step Function to monitor."
  type        = string
}

variable "rate_sns_topic_arn" {
  description = "ARN of the SNS topic for rate alarm notifications."
  type        = string
}

variable "volume_sns_topic_arn" {
  description = "ARN of the SNS topic for volume alarm notifications."
  type        = string
}

variable "sqs_queue_name" {
  description = "(Optional) Name of the SQS Dead Letter Queue to hold failed execution messages."
  type        = string
  default     = null
}

variable "sqs_kms_key_id" {
  description = "(Optional) Managed key for encryption at rest."
  type        = string
  default     = null
}

variable "sqs_message_retention_seconds" {
  description = "(Optional) SQS message retention period in seconds."
  type        = number
  default     = 604800
}

variable "sqs_visibility_timeout_seconds" {
  description = "(Optional) SQS visibility timeout in seconds."
  type        = number
  default     = 2
}

variable "eventbridge_rule_name" {
  description = "(Optional) Name of the EventBridge Rule."
  type        = string
  default     = null
}

variable "alarms_period" {
  description = "(Optional) Period in seconds for CloudWatch alarms."
  type        = number
  default     = 60
}

variable "alarms_datapoints_to_alarm" {
  description = "(Optional) Number of data points that must breach to trigger the alarm."
  type        = number
  default     = 2
}

variable "alarms_evaluation_periods" {
  description = "(Optional) Number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 2
}

variable "eventbridge_pipe_name" {
  description = "(Optional) The name of the Pipe."
  type        = string
  default     = null
}

variable "eventbridge_pipe_batch_size" {
  description = "(Optional) Batch size for EventBridge Pipe processing."
  type        = number
  default     = 1
}

variable "eventbridge_pipe_log_level" {
  description = "(Optional) Logging level for EventBridge Pipe."
  type        = string
  default     = "ERROR"
}

variable "cloudwatch_log_retention_days" {
  description = "(Optional) The number of days to retain logs in AWS CloudWatch before they are automatically deleted."
  type        = number
  default     = 90
}

variable "target_step_function_input_template" {
  description = "(Optional) The transformation template to prepare dead letter messages to be sent as step function re-execution input."
  type        = string
  default     = "<$.detail.input>"
}

variable "sns_kms_key_id" {
  description = "(Optional) Managed key for encryption at rest. Defaults to null."
  type        = string
  default     = null
}

variable "rate_alarm_name" {
  description = "(Optional) Name of the rate alarm. Defaults to null."
  type        = string
  default     = null
}

variable "volume_alarm_name" {
  description = "(Optional) Name of the volume alarm. Defaults to null."
  type        = string
  default     = null
}

variable "state_machine_arns" {
  description = "List of Step Function ARNs to monitor."
  type        = list(string)
}
