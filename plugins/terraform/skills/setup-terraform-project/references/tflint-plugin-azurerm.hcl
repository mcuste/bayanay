# TFLint Azure Provider Plugin
# Validates Azure-specific resources: deprecated args, invalid configurations.

plugin "azurerm" {
  enabled = true
  version = "0.31.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
