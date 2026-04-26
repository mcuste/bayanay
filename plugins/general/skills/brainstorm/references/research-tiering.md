# Research Tiering

Decides when to search, when to assert from training, when to refuse. NEVER make up volatile claims.

## Tiers

- **Stable** — assert from training, no citation required
  - Examples: algorithms (binary search, merge sort), well-known patterns (CQRS, circuit breaker), CS fundamentals, basic networking, basic OS, core SQL, core HTTP
- **Volatile** — MUST WebSearch + cite URL
  - Examples: current library APIs, version-specific behavior, vendor pricing/limits, framework comparisons, recent best practices, current OSS project state, recent CVEs
- **Contested** — MUST cite or label as opinion
  - Examples: strong opinion claims, "X is faster than Y", "everyone uses Z now", "industry standard is W"
- **Unknown** — refuse to assert; say "don't know — would need to verify"
  - Examples: anything outside training cutoff, anything user asserts as recent

## Researcher Skill Discovery

Before raw WebSearch, check if topic matches a `*-researcher` skill in available plugins:

- Terraform / cloud infra → `Skill("terraform:terraform-researcher")`
- Rust → `Skill("rust:rust-researcher")` (if exists)
- Python → `Skill("python:python-researcher")` (if exists)

Researcher skills have curated reference lists and domain expertise. Prefer them over raw WebSearch when topic matches.

If unsure whether researcher skill exists, glob `plugins/*/skills/*-researcher/SKILL.md` first.

## Citation Format

Inline:

```markdown
Postgres 17 supports incremental backups [docs](https://www.postgresql.org/docs/17/backup-incremental.html).
```

Aggregated in WIP and final notes file:

```markdown
## Sources

- [Postgres 17 incremental backup docs](https://www.postgresql.org/docs/17/backup-incremental.html) — confirmed feature exists, version requirement
- [AWS S3 pricing](https://aws.amazon.com/s3/pricing/) — verified cost assumption for archive tier
```

Each source: title, URL, what it was used for. NEVER paste source without explaining use.

## Refusal Format

When volatile claim can't be sourced:

> "Don't know current state of {claim}. Would need to verify against {specific source: docs, repo, vendor page}. Want me to search?"

User decides whether to spend research time. NEVER guess and present as fact.

## Source Quality

Prefer:

- Official docs (postgresql.org/docs, aws.amazon.com/docs, doc.rust-lang.org)
- Project repos (github.com/{org}/{proj} for source-truth on behavior)
- RFC/spec documents (ietf.org, w3.org)
- Maintainer blog posts on official domain

Avoid:

- Stack Overflow answers older than 2 years for volatile claims
- Tutorial sites (geeksforgeeks, w3schools) for current API behavior
- AI-generated content farms

When only low-quality sources available: cite anyway, label "secondary source — verify before relying."
