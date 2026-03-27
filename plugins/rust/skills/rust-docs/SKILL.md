---
name: rust-docs
description: "Document Rust code and fix existing documentation — generates rustdoc for public APIs, adds dev notes for non-obvious decisions, and detects/removes noisy or redundant comments in the same pass. This skill should be used proactively. Use when: 'document this Rust code', 'add docs', 'fix docs', 'clean up comments', 'rustdoc', 'add doc comments', 'remove noisy comments', 'document public API', 'why comments', 'SAFETY comments'."
argument-hint: "<file paths or description of code to document>"
allowed-tools: "Read, Glob, Grep, Edit, Write, Bash(cargo doc --document-private-items 2>&1 | head*)"
model: sonnet
effort: high
---

# Rust Docs

Single-pass: generate missing, fix noisy, leave good alone.

## Process

1. **LOAD** — read target files, `Cargo.toml`, `references/rules.md`
2. **DETECT** — check `Cargo.toml` for crate kind:
   - **Published** — has `version` + `license`/`description`, no `publish = false` → **library rules**
   - **Internal** — `publish = false`, binary-only, or no publish metadata → **application rules**
3. **SCAN** — classify each item: **Missing** (generate), **Noisy** (delete/rewrite), **Good** (skip)
4. **APPLY** — edit files, one pass
5. **VERIFY** — `cargo doc --document-private-items 2>&1 | head -50`

## Decision Gate

Before writing ANY doc: "Does this tell reader something not already in item name + type signature?"

- **Yes** → write it
- **No** → skip. If exists, delete it.

Silence > noise. Fewer valuable docs > comprehensive restated-code docs.

## Information Hierarchy

Prefer higher over lower:

1. **Type system** — `NonZeroU32` over `/// Must be non-zero`
2. **Good names** — rename before commenting
3. **Rustdoc** — contract, examples, errors, panics, safety
4. **`//` comments** — why-comments for non-obvious decisions
5. **Nothing** — when 1–4 cover it

## Coverage: Library Rules (published crates)

Goal: docs.rs reader understands full API without source.

**Every `pub` item needs:**

- Summary line (imperative fragment, one sentence)
- Extended description when summary insufficient
- `# Safety` on every `unsafe fn`
- `# Errors` on every `Result`-returning fn — each variant
- `# Panics` when fn can panic
- `# Examples` on non-trivial fns — minimal, primary use case
- Intra-doc links: `` [`Config`] ``, `` [`Self::new`] ``

**Still skip even for libraries:**

- Echo docs (decision gate still applies)
- Trait impl methods where trait documents contract
- Delegation/newtype forwarding methods
- `# Examples` on trivial getters/simple constructors

**Trivial getters:** document only with non-obvious info (defaults, valid ranges, field relationships). "Returns the name" = noise. "User-facing display name, may differ from login username" = value.

## Coverage: Application Rules (internal crates)

Document only what helps next developer. Most internal code communicates through names + types.

**Document:**

- Complex public fns with non-obvious contracts
- `unsafe fn` and `unsafe {}` blocks (always)
- Error types with non-obvious variants
- Fns where behavior diverges from name
- Module `//!` only when purpose unclear from name + contents

**Skip:**

- Obvious CRUD, handlers, glue
- Self-explanatory structs/fields
- Fns where name + signature = full contract
- Private items (unless non-obvious invariant)

## Generation Format

### Rustdoc (`///`)

- Summary: imperative fragment, one sentence. "Returns active connections" not "This method returns a list of all currently active connections"
- Extended description: only when summary insufficient
- `# Safety`, `# Errors`, `# Panics`: per coverage level
- `# Examples`: per coverage level, minimal
- Intra-doc links for referenced types

### Dev Notes (`//`)

- `// SAFETY:` before every `unsafe {}` — why invariants hold
- `// WORKAROUND:` with issue link
- `// TODO:`/`// FIXME:` with issue number or context
- Why-comments: non-obvious invariants, perf choices, magic numbers, regex, bitwise ops, safe `unwrap()` reasoning

**Never generate:** narration comments, section headers, stdlib explanations, rot-prone comments.

## Fixing Existing Docs

Apply every `NEVER` rule from `references/rules.md`:

- **Echo docs** → delete (or rewrite if item needs real docs)
- **Commented-out code** → delete
- **Narration/section headers** → delete
- **Bare TODO/FIXME** → add context or delete
- **Stale comments** referencing hardcoded values → delete

Deleting: remove line entirely, collapse blank lines.

## Scope

- Only target files explicitly requested or clearly related
- Don't document entire codebase for one-module request
- Don't add crate-level docs unless asked or `lib.rs` in scope
- Preserve existing good docs — don't rewrite for style

## Reference

Read `references/rules.md` for full rule IDs and details.
