variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "lambda_async_config_maximum_retry_attempts" {
  description = "Maximum retry attempts for async Lambda invocations"
  type        = number
  default     = 2
}

variable "lambda_async_config_maximum_event_age_in_seconds" {
  description = "Maximum event age in seconds for async Lambda invocations"
  type        = number
  default     = 3600
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "example-queue"
}

variable "sqs_message_retention_seconds" {
  description = "Message retention period for the SQS queue in seconds"
  type        = number
  default     = 345600
}

variable "sqs_visibility_timeout_seconds" {
  description = "Visibility timeout for the SQS queue in seconds"
  type        = number
  default     = 30
}

variable "sqs_kms_key_id" {
  description = "KMS key ID for the SQS queue"
  type        = string
  default     = ""
}
