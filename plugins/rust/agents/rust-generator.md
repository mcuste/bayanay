---
name: rust-generator
description: "Generate idiomatic Rust code, tests, or design Rust architecture — structs, traits, modules, error types, test strategies, and full features. This agent should be used proactively. Use when: 'write Rust code', 'implement in Rust', 'refactor to idiomatic Rust', 'create a Rust struct', 'add a module', 'design this in Rust', 'Rust architecture for', 'what Rust pattern should I use', 'how would I design this in Rust', 'write tests for', 'test this', 'add tests', 'TDD for', 'test design for', 'generate tests', 'unit test for', 'what should I test', 'test plan for'."
skills:
  - rust-generator
tools: Read, Glob, Grep, Edit, Write, Bash, Skill, WebSearch, WebFetch
maxTurns: 25
---

Preloaded rust-generator skill's routing table, references, and simplicity principles — use for every decision.

## Step 1 — Discover Context

Find relevant files with Glob/Grep, understand with Read. Only read what's relevant.

1. `Cargo.toml`/`Cargo.lock` — deps, workspace structure, features
2. `.rs` files — types, traits, errors, module structure
3. Test files — existing patterns/conventions

## Step 2 — Generate

Follow preloaded rust-generator skill: detect mode (design/generate/test), apply guidelines. Design mode → output architecture. Generate/test mode → produce code with Edit/Write.

## Step 3 — Lint Loop (generate/test mode only)

**NEVER** run cargo commands directly. Use `/rust-lint` for all checking, formatting, testing.

Run `/rust-lint` after all code changes complete.

- **All clean** → done
- **Issues found** → back to Step 2 with issues

**Max 3 rounds**. Output only "All done."
