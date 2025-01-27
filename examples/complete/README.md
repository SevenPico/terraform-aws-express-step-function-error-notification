# Example

This example demonstrates how to use the `express_step_function_error_notification` module to send error notifications for a given Step Function. It uses KMS encryption for the SQS Dead Letter Queue.

The example creates the following prerequisite resources:

- A KMS key
- 3 Step Functions
- 2 SNS topics

Then it uses their outputs to configure the `express_step_function_error_notification` module. The module creates the following resources:

- 3 Log Group Subscription Filters (1 per Step Function)
- 1 Lambda function
- 3 EventBridge Rules (1 per Step Function)
- 3 SQS queues with KMS encryption (1 per Step Function)
- 6 CloudWatch Alarms with SNS actions (2 per Step Function)
  - with permission to publish to KMS encrypted SNS topics

## Prerequisites

- [terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- [aws cli](https://aws.amazon.com/cli/)

## Environment Variables

Create a `.env` file with the following environment variable exports:

```bash
export AWS_REGION="your-aws-region"
export AWS_DEFAULT_REGION="your-aws-region"
export NAMESPACE="your-namespace"
export TENANT="your-tenant"
export ENVIRONMENT="your-environment"
export ROOT_DOMAIN="your-root-domain"
export TFSTATE_BUCKET="your-tfstate-bucket"
export TFSTATE_LOCK_TABLE="your-tfstate-lock-table"
export ENABLED=false
```

Then run `source .env` to load the environment variables.

## Usage

Use Terragrunt to run the example.
Before running the commands below, get the AWS environment variables for the account you want to deploy to.

```bash
export AWS_ACCESS_KEY_ID="your-aws-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-aws-secret-access-key"
export AWS_SESSION_TOKEN="your-aws-session-token"
```

Then run the following commands to deploy the example:

```bash
terragrunt init
terragrunt plan
terragrunt apply
```

Of course, that will only deploy the context since all the AWS resources are not enabled by default. You must set your environment variable `ENABLED=true` to deploy the AWS resources.

```bash
export ENABLED=true
terragrunt plan
terragrunt apply
```
