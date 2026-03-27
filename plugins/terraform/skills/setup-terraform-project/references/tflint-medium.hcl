# TFLint Preset: Medium — Recommended starting point for serious projects
# All bundled rules enabled. Naming conventions and documentation enforced as warnings.

plugin "terraform" {
  enabled = true
  preset  = "all"
}

# Promote key rules from notice to warning
rule "terraform_naming_convention" {
  enabled  = true
  severity = "warning"
}

rule "terraform_documented_variables" {
  enabled  = true
  severity = "warning"
}

rule "terraform_documented_outputs" {
  enabled  = true
  severity = "warning"
}
