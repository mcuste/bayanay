---
name: python-implement
description: "Implement Python code in a generator-evaluator loop — generates idiomatic code, evaluates against the decision tree, fixes violations, repeats until clean. Use when: 'implement this in Python with review', 'write and evaluate Python code', 'implement Python with quality loop', 'implement and review Python'."
argument-hint: "<feature, task, or code to implement>"
allowed-tools: "Agent, Read, Glob, Grep, Bash"
effort: high
---

Implement Python code using a generator-evaluator loop. You are the orchestrator — spawn agents sequentially and pass results between them. ultrathink

## Step 1 — Generate

```text
Agent(subagent_type: "python-generator", prompt: "Implement the following:\n\n$ARGUMENTS")
```

The generator produces code and runs its own lint loop (ruff format, ruff check, pyright, pytest). When it completes, run `git diff --name-only` to capture which `.py` files were created or modified. Save these paths — they are the evaluation target for all subsequent rounds.

## Step 2 — Evaluate

```text
Agent(subagent_type: "python-evaluator", prompt: "Evaluate these Python files for idiomatic patterns and architecture:\n\n<file paths>")
```

Two outcomes:

- **"All clean"** → go to Step 3
- **Violation report** → return to Step 1, passing the violation report to the generator to fix. After it finishes, re-evaluate the same file paths.

**Stop after 3 evaluation rounds** even if violations remain — report them in Step 4.

## Step 3 — Repository Evaluation

After the file-level generate-evaluate loop is clean (or max rounds reached), run a full repository evaluation:

```text
Agent(subagent_type: "python-repo-evaluator", prompt: "Evaluate this Python repository for idiomatic patterns and architecture issues.")
```

Two outcomes:

- **"All clean"** → go to Step 4
- **Violation report** → return to Step 1, passing the violation report to the generator to fix.

**Stop after 2 full cycles** (Step 1 → Step 3) even if violations remain — report them in Step 4.

## Step 4 — Report

Output a summary:

- Files created or modified
- What was implemented
- Evaluation result (clean, or remaining violations if max cycles reached)
