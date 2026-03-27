---
name: rust-implement
description: "Implement Rust code with TDD and quality review — writes tests first, generates code, evaluates against guidelines, fixes violations. This skill should be used proactively. Use when: 'implement this in Rust with review', 'TDD in Rust', 'implement and review Rust', 'write Rust with tests', 'implement with quality loop'."
argument-hint: "<feature, task, or code to implement>"
allowed-tools: "Agent, Read, Glob, Grep, Edit, Write, Bash, Skill"
---

TDD generator-evaluator loop. You orchestrate — spawn agents sequentially, pass results between them.

## Step 0 — Assess

Determine if task needs tests. Tests needed for: new logic, functions, modules, features with testable behavior. Tests NOT needed for: pure refactors, config changes, build fixes, explicitly test-free tasks.

- **Tests needed** → Step 1
- **Tests not needed** → skip to Step 2

## Step 1 — Test Generation (Red)

```text
Agent(subagent_type: "rust:rust-generator", prompt: "Write failing tests (with `todo!()` stubs) for the following requirements. Produce the full test code, not just a plan.\n\n$ARGUMENTS")
```

Produces compilable test files that fail + test plan.

## Step 2 — Generate (Green)

```text
Agent(subagent_type: "rust:rust-generator", prompt: "$ARGUMENTS")
```

Generator produces code and runs its own lint loop. On completion, run `git diff --name-only` → save changed `.rs` paths as evaluation target for all subsequent rounds.

## Step 3 — Evaluate

```text
Agent(subagent_type: "rust:rust-evaluator", prompt: "Evaluate these Rust files:\n\n<file paths>")
```

- **"All clean"** → Step 4
- **Violations** → back to Step 2 with violation report for generator to fix, then re-evaluate same paths

**Max 3 evaluation rounds** — report remaining violations in Step 4.

## Step 4 — Document

```text
Skill(skill: "rust-docs", args: "<changed .rs file paths from Step 2>")
```

Runs rust-docs on all changed files — generates missing docs, fixes noisy ones.

## Step 5 — Report

Output:

- Files created/modified
- What was implemented
- Evaluation result (clean, or remaining violations if max rounds hit)

**NEVER** run cargo commands directly. Use `/rust-lint` if you need to check, format, or test.
