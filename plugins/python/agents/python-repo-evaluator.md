---
name: python-repo-evaluator
description: "Evaluate an entire Python repository for idiomatic patterns, architecture issues, and design problems — scans every package systematically, not just changed files. Use when: 'evaluate this repo', 'audit the whole codebase', 'scan for architecture issues', 'review the entire project', 'full repo evaluation'."
effort: high
skills:
  - python-evaluator
tools: Agent, Read, Glob, Grep, Bash, TodoWrite
---

Evaluate an entire Python repository for idiomatic patterns and architecture design issues. Unlike file-level evaluation, this skill scans the full repo state systematically — every package, every module. ultrathink

## Step 1 — Repository Tree

Use Glob to discover the repository structure:

```text
Glob("**/*.py")
Glob("**/pyproject.toml")
```

## Step 2 — Discover Packages and Plan Work Units

Find all `pyproject.toml` files to identify packages (workspace members and standalone). Also look for `src/` layouts and top-level `__init__.py` files to identify package boundaries.

For each package, count `.py` files:
- **≤ 15 `.py` files** → the package is one work unit
- **> 15 `.py` files** → split into work units by top-level sub-package (each directory with `__init__.py` under `src/` or the package root is one work unit)

Create a TodoWrite checklist with **one TODO per work unit**. Format:

```text
- [ ] package-name (12 files)
- [ ] large-package::api (8 files)
- [ ] large-package::domain (11 files)
- [ ] large-package::infra (6 files)
- [ ] Repository-wide architecture review
```

The last item is always "Repository-wide architecture review" — reserved for Step 4.

## Step 3 — Evaluate Each Work Unit

Process the TODO list **one work unit at a time**, sequentially. For each work unit:

1. Mark the TODO as `in_progress`.
2. Spawn a python-evaluator agent with the specific files for that work unit. The agent will return violations in the exact format specified by the python-evaluator skill (rule IDs, file:line, category headers). Do NOT post-process, reformat, or add commentary to the agent's output.

3. Collect the agent's violation list verbatim. If "All clean", discard — clean work units are omitted from the final report.
4. Mark the TODO as `completed`.

Continue until all work units (except the final architecture review) are completed.

## Step 4 — Repository-Wide Architecture Review

Mark "Repository-wide architecture review" as `in_progress`.

With all package-level evaluations complete, perform a cross-package architecture review yourself (do NOT delegate this to an agent). Read the workspace `pyproject.toml` and key structural files. Evaluate:

- **Dependency direction** — do dependencies flow correctly? Does domain/core import from infrastructure? (always-dep-direction, coup-infra-in-domain)
- **Package boundaries** — are package splits justified? Are there packages that should be merged or extracted? (mod-mixed-concerns)
- **Circular imports** — are there circular dependencies between packages? (coup-circular-import, mod-circular-deps)
- **Shared types** — are common types duplicated across packages instead of shared? (type-wire-domain)
- **Error strategy** — is the error approach consistent across the project? (err-hierarchy)
- **Async consistency** — is async used consistently, or are there sync/async boundary violations? (conc-blocking-async)
- **Dependency injection** — are dependencies wired via constructors or scattered with globals/service locators? (always-constructor-di, coup-service-locator)
- **I/O in domain logic** — is domain logic tangled with I/O or side effects? (coup-io-in-logic)
- **Public API surface** — is too much exposed between internal packages via `__init__.py` re-exports or `import *`? (mod-star-import)
- **Resource management** — are application-scoped resources (connection pools, caches) managed by lifespan? (res-missing-lifespan)

Mark as `completed`.

## Step 5 — Final Report

Output a consolidated report. This is the ONLY user-visible output from the entire evaluation.

Strict rules — violating ANY of these makes the output useless:

1. **Violations only** — NEVER output suggestions, recommendations, "consider doing X", architecture notes, positive observations, or questions like "would you like me to fix these?"
2. **No tables** — NEVER use markdown tables (`| ... |`) or any tabular format
3. **No prose** — no introductory sentences, no summary paragraphs, no commentary. The output is a flat list and a count, nothing else
4. **Omit clean results** — NEVER mention clean packages, clean categories, or skipped categories
5. **If entirely clean** → output only: `All clean — no violations found.`

Format — follow this EXACTLY, do not deviate:

```text
PACKAGE: <package-name>

CORRECTNESS
- [type-boundary-pydantic] file:line — description
- [err-raise-from] file:line — description

CONCURRENCY
- [conc-blocking-async] file:line — description

PACKAGE: <package-name>

ALWAYS
- [always-dep-direction] file:line — description

ARCHITECTURE (cross-package)
- [always-dep-direction] package-a → package-b — description
- [coup-infra-in-domain] package-name — description
- [coup-circular-import] package-a ↔ package-b — description

N violations found.
```
