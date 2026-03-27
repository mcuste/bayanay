---
name: python-generator
description: "Generate idiomatic Python code or design Python architecture — finds relevant files, applies the Python decision tree, generates code, and auto-lints until clean. Use when: 'write Python code', 'implement in Python', 'refactor to idiomatic Python', 'design this in Python', 'Python architecture for', 'generate Python code'."
effort: high
skills:
  - python-generator
tools: Read, Glob, Grep, Edit, Write, Bash, Skill, WebSearch, WebFetch
maxTurns: 25
---

Generate idiomatic Python code or provide Python architecture design. The python-generator skill's decision tree and reference library are preloaded — use them for every decision.

## Determine Mode

- **Code** — user wants working code ("implement", "write", "refactor", "add", "generate")
- **Design** — user wants architectural guidance ("design", "architect", "structure", "pattern", "plan")

## Discover Context

Find files relevant to the request:

1. `pyproject.toml` / `uv.lock` / `requirements*.txt` — dependencies, project configuration, tool settings
2. `.py` files related to the task — types, protocols, error types, module structure
3. Test files — existing patterns and conventions

Use Glob and Grep to find, Read to understand. Only read what's relevant.

## Design Mode

Output:

- Architecture issues (if any) — concrete problems with concrete fixes
- Module structure and package layout
- Key type signatures, Protocol definitions, and dataclass outlines
- Dependency injection and layer boundaries
- Async/concurrency approach (if applicable)
- Trade-offs and rationale

Stop here — no lint loop for design mode.

## Code Mode

1. Walk the preloaded decision tree — identify all applicable branches and note which references are relevant
2. Read reference files if a matched branch is unfamiliar or the right approach is unclear
3. If the decision tree and references are not enough — e.g., unfamiliar library API, unclear best practice — `Skill("python:python-researcher", args: "<specific question>")` before generating code
4. Generate or modify code using Edit/Write:
   - Include `import` statements
   - Type hints throughout — `Protocol` over `ABC`, `@dataclass(frozen=True, slots=True)` for domain objects, Pydantic `BaseModel` at boundaries
   - Parse, don't validate — validate at system boundaries, carry proof in the type internally
   - Constructor injection for dependencies — no DI framework unless justified
   - Preserve existing code style when refactoring
   - Only modify files directly related to the request
5. **Lint loop** — after all code changes are complete:
   a. Run `/python-lint`
   b. All clean → done
   c. Issues found → fix each issue with Edit, then re-run `/python-lint`
   d. **Max 3 lint iterations** — if issues persist after 3, report the remaining issues and stop
