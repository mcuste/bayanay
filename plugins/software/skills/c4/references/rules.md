# C4 Review Rules

Self-review: fix violations before output. Review mode: report as `C4: {filename} — [rule-id] description`.

## Accuracy

- `c4-phantom-component` — Component in diagram doesn't exist in codebase and wasn't user-confirmed.
- `c4-missing-component` — Significant code element not represented: DB connections, external APIs, queue clients, binary targets, major modules.
- `c4-wrong-technology` — Tech label doesn't match code (e.g., "Actix" but code uses Axum; "MySQL" but code uses PostgreSQL).
- `c4-stale-relationship` — Diagrammed relationship no longer exists in code.
- `c4-missing-relationship` — Two communicating components have no relationship arrow.

## Completeness

- `c4-missing-context` — No Level 1 context diagram exists.
- `c4-missing-external` — External dependency in code absent from context diagram.
- `c4-missing-actors` — Context diagram has no human actors.
- `c4-no-notes` — No Notes section in diagram file.

## C4 Model Correctness

- `c4-wrong-level` — Elements at wrong abstraction (Level 1 showing containers; Level 2 showing code components; Level 3 showing functions).
- `c4-missing-boundary` — Containers/components not in `Container_Boundary` or `System_Boundary` (Level 2+).
- `c4-vague-description` — No description or generic one ("Handles stuff", "Service").
- `c4-unlabeled-relationship` — Relationship arrow missing label for what flows and how.
- `c4-level1-tech-label` — Level 1 has technology labels (must be tech-agnostic).

## Consistency

- `c4-naming-mismatch` — Diagram names don't match module/crate/service names in code.
- `c4-cross-diagram-inconsistency` — Container in container diagram absent or renamed in component diagram.
- `c4-stale-references` — References point to nonexistent files.
