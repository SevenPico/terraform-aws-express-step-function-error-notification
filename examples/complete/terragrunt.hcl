locals {
  account_id  = get_aws_account_id()
  tenant      = get_env("TENANT")

  region = get_env("AWS_REGION")
  root_domain = get_env("ROOT_DOMAIN")

  namespace   = get_env("NAMESPACE")
  project     = "aws-xsf-errors"
  environment = get_env("ENVIRONMENT") // "eg"
  stage       = basename(get_terragrunt_dir()) //
  domain_name = "${local.stage}.${local.project}.${local.root_domain}"

  enabled = get_env("ENABLED")

  tags = { Source = "Managed by Terraform" }
  regex_replace_chars = "/[^-a-zA-Z0-9]/"
  delimiter           = "-"
  replacement         = ""
  id_length_limit     = 0
  id_hash_length      = 5
  label_key_case      = "title"
  label_value_case    = "lower"
  label_order         =  ["namespace", "project", "environment", "stage", "name", "attributes"]
  dns_name_format     = "$${name}.$${domain_name}"
}

inputs = {
  root_domain = local.root_domain

  # Standard Context
  enabled             = local.enabled
  region              = local.region
  tenant              = local.tenant
  project             = local.project
  domain_name         = local.domain_name
  project             = local.project
  namespace           = local.namespace
  environment         = local.environment
  stage               = local.stage
  tags                = local.tags
  regex_replace_chars = local.regex_replace_chars
  delimiter           = local.delimiter
  replacement         = local.replacement
  id_length_limit     = local.id_length_limit
  id_hash_length      = local.id_hash_length
  label_key_case      = local.label_key_case
  label_value_case    = local.label_value_case
  label_order         = local.label_order
  dns_name_format     = local.dns_name_format

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

}

remote_state {
  backend = "s3"
  disable_init = false
  config  = {
    bucket                = get_env("TFSTATE_BUCKET")
    disable_bucket_update = true
    dynamodb_table        = get_env("TFSTATE_LOCK_TABLE")
    encrypt               = true
    key                   = "${local.account_id}/${local.project}/${local.stage}/terraform.tfstate"
    region                = local.region
  }
  generate = {
    path      = "generated-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "providers" {
  path      = "generated-providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
  terraform {
    required_version = ">= 0.13.0"

    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = ">= 2.0"
      }
      null = {
        source  = "hashicorp/null"
        version = ">= 2.0"
      }
    }
  }

  provider "aws" {
    region  = "${local.region}"
  }
  EOF
}