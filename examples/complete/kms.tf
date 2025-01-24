# KMS Key for SQS encryption
resource "aws_kms_key" "kms_key" {
  count                  = module.context.enabled ? 1 : 0
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
        Resource = ["arn:aws:kms:${local.region}:${local.account_id}:key/*"]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })

  tags = module.context.tags
}

resource "aws_kms_alias" "kms_key_alias" {
  count         = module.context.enabled ? 1 : 0
  name          = "alias/${module.context.id}-kms-key"
  target_key_id = aws_kms_key.kms_key[0].key_id
} 