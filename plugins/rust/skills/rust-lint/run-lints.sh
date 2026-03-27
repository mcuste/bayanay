#!/usr/bin/env bash
set -euo pipefail

# Rust lint runner — checks tool availability, runs each tool, returns structured output.
# Skips tools that are not installed. Only produces output when issues are found.
#
# Usage: bash run-lints.sh
# Automatically finds the project root via `cargo locate-project`.

# Find and cd into project root
PROJECT_ROOT=$(dirname "$(cargo locate-project --message-format plain)") || {
  exit 0
}
cd "$PROJECT_ROOT"

DIVIDER="════════════════════════════════════════"
output=""
findings_count=0

# ── Helpers ──────────────────────────────────────────────────────────
has_cargo_sub() {
  local sub="$1"
  command -v "cargo-$sub" &>/dev/null || cargo "$sub" --version &>/dev/null 2>&1
}

filter_noise() {
  grep -v -E '^\s*(Compiling|Downloading|Downloaded|Finished|Building|Blocking|Updating|Locking|Packaging|Fresh|Resolving) ' \
    | grep -v -E '^\s*(PASS|ok) ' \
    | grep -v -E '^\s*Starting [0-9]+ tests' \
    | grep -v -E '^\s*[0-9]+ passed' \
    || true
}

run_tool() {
  local label="$1" tool="$2" cmd="$3"
  local tool_output exit_code
  tool_output=$(eval "$cmd" 2>&1) && exit_code=0 || exit_code=$?
  if [ $exit_code -ne 0 ]; then
    local filtered
    filtered=$(echo "$tool_output" | filter_noise)
    output+=$'\n'"$DIVIDER"$'\n'"SECTION: $label"$'\n'"TOOL: $tool"$'\n'"$DIVIDER"$'\n'"$filtered"$'\n'
    findings_count=$((findings_count + 1))
  fi
}

# ── Tool 1: cargo fmt ───────────────────────────────────────────────
cargo fmt --all 2>/dev/null || true

# ── Tool 2: cargo clippy ────────────────────────────────────────────
if has_cargo_sub "clippy"; then
  run_tool "Lints" "cargo clippy" "cargo clippy --all-features --all-targets -- -D warnings"
fi

# ── Tool 3: cargo nextest ──────────────────────────────────────────
if has_cargo_sub "nextest"; then
  run_tool "Tests" "cargo nextest run" "cargo nextest run --all-features"
fi

# ── Tool 4: cargo machete ───────────────────────────────────────────
if has_cargo_sub "machete"; then
  run_tool "Unused Dependencies" "cargo machete" "cargo machete"
fi

# ── Tool 5: cargo deny ─────────────────────────────────────────────
if has_cargo_sub "deny" && [ -f "deny.toml" ]; then
  run_tool "Dependency Lints" "cargo deny" "cargo deny check --hide-inclusion-graph"
fi

# ── Output only if there are findings ───────────────────────────────
if [ $findings_count -gt 0 ]; then
  echo "Lint issues found ($findings_count tool(s) with findings):"
  echo "$output"
  exit 1
fi

exit 0
