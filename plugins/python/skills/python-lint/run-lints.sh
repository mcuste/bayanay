#!/usr/bin/env bash
set -euo pipefail

# Python lint runner — checks tool availability, runs each tool, returns structured output.
# Skips tools that are not installed. Only produces output when issues are found.
#
# Usage: bash run-lints.sh
# Automatically finds the project root via pyproject.toml.

# Find project root by walking up from $PWD
find_project_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/pyproject.toml" ]; then
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

# Determine runner prefix — prefer `uv run` if uv.lock exists and uv is available
RUN=""
if [ -f "uv.lock" ] && command -v uv &>/dev/null; then
  RUN="uv run"
fi

DIVIDER="════════════════════════════════════════"
output=""
findings_count=0

# ── Helpers ──────────────────────────────────────────────────────────
has_tool() {
  local tool="$1"
  if [ -n "$RUN" ]; then
    $RUN "$tool" --version &>/dev/null
  else
    command -v "$tool" &>/dev/null
  fi
}

run() {
  if [ -n "$RUN" ]; then
    $RUN "$@"
  else
    "$@"
  fi
}

filter_noise() {
  grep -v -E '^\s*(Resolved|Prepared|Installed|Uninstalled|Audited|Using) ' \
    | grep -v -E '^\s*(PASSED|passed|===) ' \
    || true
}

run_tool() {
  local label="$1" tool="$2"
  shift 2
  local tool_output exit_code
  tool_output=$(run "$@" 2>&1) && exit_code=0 || exit_code=$?
  if [ $exit_code -ne 0 ]; then
    local filtered
    filtered=$(echo "$tool_output" | filter_noise)
    if [ -n "$filtered" ]; then
      output+=$'\n'"$DIVIDER"$'\n'"SECTION: $label"$'\n'"TOOL: $tool"$'\n'"$DIVIDER"$'\n'"$filtered"$'\n'
      findings_count=$((findings_count + 1))
    fi
  fi
}

# ── Detect source directory ─────────────────────────────────────────
SRC_DIR="."
if [ -d "src" ]; then
  SRC_DIR="src"
fi

# ── Tool 1: ruff format ─────────────────────────────────────────────
if has_tool ruff; then
  run ruff format . 2>/dev/null || true
fi

# ── Tool 2: ruff check ──────────────────────────────────────────────
if has_tool ruff; then
  run_tool "Lints" "ruff check" ruff check .
fi

# ── Tool 3: pip-audit ──────────────────────────────────────────────
if has_tool pip-audit; then
  run_tool "Security Audit" "pip-audit" pip-audit
fi

# ── Tool 4: pyright ──────────────────────────────────────────────────
if has_tool pyright; then
  run_tool "Type Checking" "pyright" pyright "$SRC_DIR"
fi

# ── Tool 5: pytest ──────────────────────────────────────────────────
if has_tool pytest; then
  run_tool "Tests" "pytest" pytest --tb=short -q
fi

# ── Output only if there are findings ───────────────────────────────
if [ $findings_count -gt 0 ]; then
  echo "Lint issues found ($findings_count tool(s) with findings):"
  echo "$output"
  exit 1
fi

exit 0
