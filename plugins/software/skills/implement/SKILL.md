---
name: implement
description: "Implement code using a generator-evaluator loop — detects the project language and delegates to the appropriate language-specific implement skill (rust-implement, python-implement). Use when: 'implement this', 'implement with review', 'write and evaluate code', 'implement with quality loop'."
argument-hint: "<feature, task, or code to implement>"
allowed-tools: "Skill, Read, Glob, Grep, Bash"
effort: high
---

# Implement — Language Dispatcher

**Output style:** Short and concise — lead with actions, skip preamble and filler.

Detect the project language and delegate to the correct language-specific implement skill. You are a dispatcher — do not generate or evaluate code yourself. ultrathink

## Step 1 — Detect Language

Identify the language using these signals, checked in order:

1. **Explicit language in `$ARGUMENTS`** — if the user wrote "in Rust", "in Python", etc., use that directly. Skip detection.
2. **Project markers** — check for manifest files using `Glob`:

   | Marker                                                        | Language | Skill                     |
   |---------------------------------------------------------------|----------|---------------------------|
   | `Cargo.toml`                                                  | Rust     | `rust:rust-implement`     |
   | `pyproject.toml`, `setup.py`, `setup.cfg`, `requirements.txt` | Python   | `python:python-implement` |

3. **Source files** — if no markers found, glob for source files (`**/*.rs`, `**/*.py`). Map extensions to languages using the table above.

Resolution:

- **Single language detected** — use it.
- **Multiple languages detected** — ask the user which one to target.
- **No supported language detected** — tell the user which languages have implement skills (Rust, Python) and ask them to specify.

## Step 2 — Delegate

Invoke the matched skill, passing `$ARGUMENTS` through unchanged:

```text
Skill("rust:rust-implement", args: "$ARGUMENTS")
```

```text
Skill("python:python-implement", args: "$ARGUMENTS")
```

Do not modify, summarize, or reinterpret the arguments.

## Step 3 — Report

The language-specific skill produces its own report. Do not duplicate or summarize it again.
