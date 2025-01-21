# KMS Key for SQS encryption
resource "aws_kms_key" "sqs_key" {
  description             = "KMS key for SQS queue encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current[0].account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EventBridge to use the key"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = module.context.tags
}

resource "aws_kms_alias" "sqs_key_alias" {
  name          = "alias/${module.context.id}-sqs-key"
  target_key_id = aws_kms_key.sqs_key.key_id
} 