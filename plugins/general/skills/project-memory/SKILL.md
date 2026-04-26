---
name: project-memory
description: "Curate the `## Project Memory` block in CLAUDE.md as long-lived decision memory steering generators (rust/python/terraform/etc.) toward chosen patterns and trade-offs. Invoke PROACTIVELY — without being asked — whenever the user commits to an architecture, pattern, major dependency, or cross-cutting trade-off in conversation (e.g. 'let's use X', 'we'll go with Y', 'going to standardize on Z', 'switch to W instead of V', 'we'll always do A here'), and also on explicit requests. Skip for naming, formatting, single-file logic, one-off bug fixes, transitional notes, plain choices without non-obvious rationale, or anything discoverable from deps/--help/README/schema/code. Bias toward refusal; only durable trade-offs and non-obvious constraints survive. Trigger phrases: 'CLAUDE.md', 'project memory', 'decision memory', 'remember decision', 'add to CLAUDE.md', 'extract decisions from <doc>', 'we decided X', 'let's use X', 'going with Y', 'standardize on Z'."
argument-hint: "<decision text verbatim | doc path | 'for <subdir>: <decision>' | 'for project: <decision>'>"
effort: medium
version: 2.5.0
allowed-tools: "Read, Glob, Grep, Write, Edit"
---

# Project Memory

Manage the `## Project Memory` block in `CLAUDE.md`. One bullet = one durable decision that steers generators. Not for naming, formatting, single-file logic, or one-off fixes.

**Output style:** caveman. Drop articles/filler/hedging. Skip caveman for security or irreversible-action warnings.

## Managed Block

Skill owns a marker-bounded region at the **top** of the target `CLAUDE.md`:

```
<!-- project-memory:start -->
## Project Memory

- {decision bullet}
<!-- /project-memory -->

{pre-existing user content untouched below}
```

Never hand-edit between markers — invoke this skill. Content outside markers stays byte-identical.

## Pipeline

`$ARGUMENTS` empty → print usage hint, abort.

### Step 1: Parse input

Strip target prefix:

- `for project: …` → target = `<repo_root>/CLAUDE.md`
- `for <subdir>: …` → target = `<subdir>/CLAUDE.md` (subdir missing → abort)
- no prefix → target = `<repo_root>/CLAUDE.md`

Remaining text = path or decision text.

### Step 2: Build candidates

- **Path to existing file** — scan source. ADR → `## Decision`. Brainstorm → `## Decisions` / `## Conclusion`. RFC/PRD/plan/other → loose scan. Normalize each to one line ≤ 200 chars. Pull only durable trade-offs and non-obvious constraints; skip implementation details, schema restatements, and historical/transitional notes.
- **Decision text** — one candidate if ≤ 200 chars and one idea. Else compress to one bullet. Split only when truly distinct durable decisions. Prefer fewer, sharper bullets.

Skill decides. No user prompt. Bias toward refusal.

### Step 3: Quality gate

Per candidate. **Default = refuse.** Accept only if both checks pass AND no hard-refuse category applies. Refused → print `refused. <category> → <where it belongs>. aborted.` Drop. No override.

**Check 1 — name rejected alternative.** Bullet must state concretely what project chose *not* to do. Plain choice ("uses X") without explicit "instead of Y" → refuse as plain choice.

**Check 2 — invisible rationale.** Where would generator find the *why* if CLAUDE.md vanished? If answer is any of:

- code (struct shapes, fn behavior, control flow, error returns, channel sizes)
- schema files (YAML/JSON schema, type defs, field docs)
- CLI `--help` / flag descriptions / default values
- dep manifest (Cargo.toml, package.json, pyproject.toml, etc.)
- README / public docs / git log

→ refuse: `refused. discoverable → <source>. aborted.`

**Hard-refuse categories** — apply even when bullet wears a parenthetical rationale:

- file/dir layout details (run dirs, output paths, naming patterns, PID-suffix tricks)
- schema field semantics (what `X` does, what `Y` is keyed on, validation behavior, parse-time errors/warnings)
- data structure choices (IndexMap vs HashMap, vector vs slice)
- error/warning message contents
- flag descriptions / default values / subcommand listings
- transitional/historical notes (replaces X, migrated from Y, no backcompat with Z)
- implementation details (kill_on_drop, lossy decode, retry counts, buffer sizes)

**Accept categories:**

- **Trade-off with invisible rationale** — names rejected alternative AND *why* lives nowhere in code/schema/help/manifest/README. Form: `<choice> not <alt> (<invisible-why>)`.
- **Volatility / risk warning** — flags unstable external contract a generator would otherwise trust.
- **Hard invariant not expressed in code** — must-not / hard limit a generator could violate without realizing.
- **Cross-cutting convention binding multiple files or languages** — pattern crossing module boundaries, not enforced by linter/type system.

Goal: a handful of sharp bullets, not a catalogue. **When in doubt, refuse.**

### Step 4: Read target

Read target file. Locate marker pair:

- File missing → bootstrap empty.
- Zero pairs + `## Project Memory` heading exists → wrap heading, harvest bullets.
- Zero pairs + no heading → prepend markers; preserve file below.
- One pair → harvest bullets.
- ≥ Two pairs → `multiple marker pairs in <target>. fix manually.` Abort.

### Step 5: Merge

Per candidate vs existing bullets:

- **duplicate** → skip; print `duplicate of: <existing>. no change.`
- **refinement** → edit existing in place.
- **supersede** → replace existing.
- **negation** (`no longer X` / `drop X`) → remove existing; do not add.
- **conflict** → resolve: merge into qualified bullet, auto-scope to subdir, or supersede. Print both originals + resolution + reason. Continue batch.
- **new** → append.

### Step 6: Write

Emit target file. Markers wrap the block. Content outside markers unchanged.

## Examples

**Accept:**

- `Invoke claude as subprocess; not Anthropic SDK (preserves MCP/hooks/agent loop — invisible from Cargo.toml).`
- `claude --output-format json envelope + --effort flag are VOLATILE — risk silent break on upgrade.`
- `Fail-fast: cancel siblings + abort downstream on first error. No best-effort/drain mode.`

**Refuse — looks like trade-off but isn't (parenthetical rationale dressing schema/impl fact):**

- `tasks is map keyed by id (IndexMap preserves order)` → `refused. schema restatement → schema file. aborted.`
- `depends_on pure ordering; no implicit upstream-output append` → `refused. schema semantics → schema/docs. aborted.`
- `Run dir ./.loom/runs/{ts}-{pid}/...; PID prevents same-second collision` → `refused. layout detail → code/README. aborted.`
- `Parse-time: unknown {{X}} errors; unused depends_on warns` → `refused. error behavior → parser code. aborted.`
- `Default concurrency = 3 (rate-limit conservative)` → `refused. discoverable → --help. aborted.`

**Refuse — kind:**

- `refused. naming → linter. aborted.`
- `refused. plain choice → no rejected alternative. aborted.`
- `refused. historical note → README/git log. aborted.`
- `refused. discoverable → Cargo.toml. aborted.`

**Conflict:** `conflict. existing: <X>. new: <Y>. resolved: merge → <Z> (both apply, qualifier added).`
