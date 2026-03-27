---
name: python-lint
description: Lint Python code — run ruff format, ruff check, pip-audit, pyright, and pytest. Use when asked to lint, check, or audit a Python project.
argument-hint: "<workspace or project path>"
model: haiku
allowed-tools: "Bash(bash **/run-lints.sh)"
---

# Python Lint

## Run

```bash
bash ${CLAUDE_SKILL_DIR}/run-lints.sh
```

## Summary

Summarize the output. One line per finding:

```text
- [ruff:E501] src/myproject/api.py:42 — line too long (82 > 100)
- [pip-audit] requests==2.28.0 — PYSEC-2023-74 (CVE-2023-32681)
- [pyright:reportArgumentType] src/myproject/services.py:17 — expected str, got int
- [pytest] tests/test_api.py::test_create_user — assertion failed: expected 42, got 0
- [fmt] formatting applied
```

Drop compiler noise, suggestion diffs, and help text — only violations.

If the output is empty or all clean: `All lints clean.`
