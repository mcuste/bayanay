# TFLint Google Provider Plugin
# Validates GCP-specific resources: deprecated args, invalid configurations.

plugin "google" {
  enabled = true
  version = "0.39.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}
