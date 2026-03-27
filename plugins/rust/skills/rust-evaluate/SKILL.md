---
name: rust-evaluate
description: "Evaluate an entire Rust repository for idiomatic patterns, architecture issues, test quality, and design problems — scans every crate systematically. This skill should be used proactively. Use when: 'evaluate this repo', 'audit the whole codebase', 'scan for architecture issues', 'review the entire project', 'full repo evaluation', 'codebase review'."
allowed-tools: "Agent, Read, Glob, Grep, Bash, TodoWrite"
---

Scan every crate. Idiomatic patterns, architecture, performance, test quality.

## Step 1 — Discover

!`find . -name '*.rs' -not -path '*/target/*' | sort`
!`find . -name 'Cargo.toml' -not -path '*/target/*' | sort`

## Step 2 — Plan

`Cargo.toml` → crates. Count `.rs` per crate:

- **≤15 files** → one work unit
- **>15 files** → split by top-level `mod` subtree; `tests/` = own unit

TodoWrite checklist:

```text
- [ ] crate-name (12 files)
- [ ] large-crate::api (8 files)
- [ ] large-crate::domain (11 files)
- [ ] large-crate [tests] (4 test files)
```

## Step 3 — Evaluate

Work units **sequentially**:

1. TODO → `in_progress`
2. `Agent(subagent_type: "rust:rust-evaluator", prompt: "Evaluate these Rust files:\n\n<file paths>")`
3. Collect violations verbatim. "All clean" → discard. No post-processing.
4. TODO → `completed`

## Step 4 — Final Report

From collected findings: keep max 5 per crate, ranked: correctness > safety > architecture > performance > style. ONLY user-visible output from entire evaluation.

1. Violations only. No suggestions, positives, questions.
2. No tables. No prose. No intros/summaries.
3. Clean crates → omit. Entirely clean → `All clean — no violations found.`
4. Same root cause, multiple sites → ONE entry, list all locations.
5. Root-cause filter — suppress symptoms:
   - Higher tier explains lower → drop lower. Tiers: `project-structure` → `type-design` → `error-handling` → `concurrency` → `unsafe` → `idioms`
   - B consequence of A → drop B

Format:

```text
CRATE: <crate-name>

- file:line — description
- file:line — description

CRATE: <crate-name>

- file:line — description

N violations found.
```
