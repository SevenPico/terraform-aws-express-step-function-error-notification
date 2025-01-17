## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./_outputs.tf
##  This file contains code written only by SevenPico, Inc.
## ----------------------------------------------------------------------------

output "sqs_dead_letter_queue_arn" {
  description = "ARN of the SQS Dead Letter Queue."
  value       = try(aws_sqs_queue.dead_letter_queue[0].arn, "")
}

output "cloudwatch_rate_alarm_name" {
  description = "Name of the CloudWatch Rate Alarm."
  value       = try(aws_cloudwatch_metric_alarm.rate_alarm[0].alarm_name, "")
}

output "cloudwatch_volume_alarm_name" {
  description = "Name of the CloudWatch Volume Alarm."
  value       = try(aws_cloudwatch_metric_alarm.volume_alarm[0].alarm_name, "")
}

output "eventbridge_pipe_name" {
  description = "Name of the EventBridge Pipe."
  value       = try(aws_pipes_pipe.pipe[0].name, "")
}

output "eventbridge_pipe_arn" {
  description = "ARN of the EventBridge Pipe."
  value       = try(aws_pipes_pipe.pipe[0].arn, "")
}
