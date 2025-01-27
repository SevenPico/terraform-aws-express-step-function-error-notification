variable "step_functions" {
  description = "Map of Express Step Functions to monitor"
  type = map(object({
    arn                   = string
    log_group_name        = optional(string)
    sqs_queue_name        = optional(string)
    rate_alarm_name       = optional(string)
    volume_alarm_name     = optional(string)
    eventbridge_rule_name = optional(string)
  }))
}

variable "rate_sns_topic_arn" {
  description = "ARN of the SNS topic for rate alarm notifications."
  type        = string
}

variable "volume_sns_topic_arn" {
  description = "ARN of the SNS topic for volume alarm notifications."
  type        = string
}

variable "sqs_message_retention_seconds" {
  description = "(Optional) SQS message retention period in seconds."
  type        = number
  default     = 604800
}

variable "sqs_visibility_timeout_seconds" {
  description = "(Optional) SQS visibility timeout in seconds."
  type        = number
  default     = 30
}

variable "alarms_period" {
  description = "(Optional) Period in seconds for CloudWatch alarms."
  type        = number
  default     = 60
}

variable "alarms_datapoints_to_alarm" {
  description = "(Optional) Number of data points that must breach to trigger the alarm."
  type        = number
  default     = 1
}

variable "alarms_evaluation_periods" {
  description = "(Optional) Number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 5
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

variable "sqs_kms_key_config" {
  description = "(Optional) When present, all generated SQS queues will be encrypted with the provided KMS key. If not provided, default AWS managed keys will be used."
  type = object({
    key_id  = string
    key_arn = string
  })
  default = null
}
