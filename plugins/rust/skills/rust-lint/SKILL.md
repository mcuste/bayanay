---
name: rust-lint
description: "Lint Rust code — run cargo fmt, clippy, tests, cargo-deny, and cargo-machete. This skill should be used proactively. Use when: 'lint this', 'run clippy', 'format Rust code', 'cargo fmt', 'check for warnings', 'audit dependencies', 'check Rust project'."
argument-hint: "<workspace or crate path>"
model: haiku
effort: low
allowed-tools: "Bash(bash **/run-lints.sh)"
---

!`bash ${CLAUDE_SKILL_DIR}/run-lints.sh`

## Summary

One line per finding. Drop compiler noise, suggestion diffs, help text — violations only.

```text
- [clippy::lint-name] src/lib.rs:42 — remove explicit return
- [nextest] tests::my_test — assertion failed: expected 42, got 0
- [machete] serde_json — unused dependency in my-crate
- [deny] openssl 1.0.2 — vulnerability RUSTSEC-2023-0001
- [fmt] formatting check failed
```

If all clean: `All lints clean.`
