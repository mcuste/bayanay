#!/usr/bin/env bash
set -euo pipefail

# Terraform lint runner — checks tool availability, runs each tool, returns structured output.
# Skips tools that are not installed. Only produces output when issues are found.
#
# Usage: bash run-lints.sh
# Automatically finds the project root by walking up from $PWD looking for .tf files.

# Find project root by walking up from $PWD
find_project_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    # shellcheck disable=SC2012
    if ls "$dir"/*.tf &>/dev/null; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_project_root) || {
  exit 0
}
cd "$PROJECT_ROOT"

DIVIDER="════════════════════════════════════════"
output=""
findings_count=0

# ── Helpers ──────────────────────────────────────────────────────────
has_tool() {
  command -v "$1" &>/dev/null
}

filter_noise() {
  grep -v -E '^\s*(Initializing|Reusing|Installing|Installed|Using|Finding|Downloading|Downloaded|Upgrading) ' \
    | grep -v -E '^\s*- ' \
    | grep -v -E '^\s*$' \
    | grep -v -E '^Terraform has been successfully initialized' \
    | grep -v -E '^You may now begin working' \
    | grep -v -E '^Success!' \
    || true
}

run_tool() {
  local label="$1" tool="$2"
  shift 2
  local tool_output exit_code
  tool_output=$("$@" 2>&1) && exit_code=0 || exit_code=$?
  if [ $exit_code -ne 0 ]; then
    local filtered
    filtered=$(echo "$tool_output" | filter_noise)
    if [ -n "$filtered" ]; then
      output+=$'\n'"$DIVIDER"$'\n'"SECTION: $label"$'\n'"TOOL: $tool"$'\n'"$DIVIDER"$'\n'"$filtered"$'\n'
      findings_count=$((findings_count + 1))
    fi
  fi
}

# ── Tool 1: terraform fmt ──────────────────────────────────────────
if has_tool terraform; then
  terraform fmt -recursive 2>/dev/null || true
fi

# ── Tool 2: terraform validate ─────────────────────────────────────
if has_tool terraform; then
  # init with -backend=false to skip remote state — only need provider schemas
  terraform init -backend=false -input=false -no-color >/dev/null 2>&1 || true
  run_tool "Validation" "terraform validate" terraform validate -no-color
fi

# ── Tool 3: tflint ─────────────────────────────────────────────────
if has_tool tflint; then
  tflint --init >/dev/null 2>&1 || true
  run_tool "Lints" "tflint" tflint --no-color --recursive
fi

# ── Tool 4: trivy config ──────────────────────────────────────────
if has_tool trivy; then
  run_tool "Security (Trivy)" "trivy config" trivy config --severity HIGH,CRITICAL --exit-code 1 .
fi

# ── Tool 5: checkov ───────────────────────────────────────────────
if has_tool checkov; then
  run_tool "Security (Checkov)" "checkov" checkov -d . --framework terraform --compact --quiet
fi

# ── Output only if there are findings ───────────────────────────────
if [ $findings_count -gt 0 ]; then
  echo "Lint issues found ($findings_count tool(s) with findings):"
  echo "$output"
  exit 1
fi

exit 0
