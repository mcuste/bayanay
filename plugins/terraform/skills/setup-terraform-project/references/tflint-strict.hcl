# TFLint Preset: Strict — Maximum enforcement for production and shared modules
# All bundled rules enabled. Key rules promoted to error severity.

plugin "terraform" {
  enabled = true
  preset  = "all"
}

# Correctness — must fix
rule "terraform_unused_declarations" {
  enabled  = true
  severity = "error"
}

rule "terraform_required_providers" {
  enabled  = true
  severity = "error"
}

rule "terraform_required_version" {
  enabled  = true
  severity = "error"
}

rule "terraform_module_pinned_source" {
  enabled  = true
  severity = "error"
}

rule "terraform_module_version" {
  enabled  = true
  severity = "error"
}

rule "terraform_typed_variables" {
  enabled  = true
  severity = "error"
}

# Style & documentation — enforced
rule "terraform_naming_convention" {
  enabled  = true
  severity = "error"
}

rule "terraform_standard_module_structure" {
  enabled  = true
  severity = "error"
}

rule "terraform_documented_variables" {
  enabled  = true
  severity = "warning"
}

rule "terraform_documented_outputs" {
  enabled  = true
  severity = "warning"
}

rule "terraform_comment_syntax" {
  enabled  = true
  severity = "warning"
}
