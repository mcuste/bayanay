# TFLint AWS Provider Plugin
# Validates AWS-specific resources: instance types, AMIs, deprecated args, missing tags.

plugin "aws" {
  enabled = true
  version = "0.46.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
