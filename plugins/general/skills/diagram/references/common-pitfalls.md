# Common Pitfalls

Check these before outputting your diagram. Fix any issues found.

---

## All Diagram Types

- **Init block:** must be copied verbatim from `assets/material-theme.txt` — never reconstruct from memory
- **One relationship per line:** never chain arrows (`A --> B --> C` is wrong; use two separate lines)
- **Node labels:** max ~30 chars; IDs must be short and contain no special characters

---

## `flowchart`

- Subgraph IDs must not contain spaces or hyphens — use camelCase or underscores
- Edge labels with spaces must be quoted: `-->|"label text"|` or `-- label text -->`
- Do not mix `-->` and `---` styles on the same edge

---

## `sequenceDiagram`

- Use `rect rgb(200,230,201)` / `rect rgb(248,187,208)` blocks for semantic coloring — `classDef` is not supported
- Participant aliases must be declared before use: `participant C as Client`
- Max ~6 participants before splitting into two diagrams

---

## `classDiagram`

- `classDef` application **must be inline** — use `class ClassName:::classDefName { ... }` syntax
- Standalone `ClassName:::classDefName` lines (outside a class body) cause parse errors

---

## `block-beta`

- `classDef` / `:::` is **not supported** inside nested `block:...:end` containers — use `style nodeId fill:...,stroke:...,color:...` statements after all `end` keywords instead
- **If the diagram has connections between nodes, do not use `block-beta`.** Switch to `flowchart TD/LR` with `subgraph` boundaries — block-beta has fixed grid layout with poor edge routing (arrows pass through other nodes)

---

## `architecture-beta`

- Labels must contain **alphanumeric characters and spaces only** — no `.` `-` `/` `[` `]` or other punctuation
  - `Node.js` → `NodeJS`
  - `ECS - API` → `ECS API`
  - `us-east-1` → `us east 1`
- If labels require special characters, fall back to `flowchart TD` with `subgraph` for boundaries

---

## `requirementDiagram`

- **No hyphens** in identifiers, `id:` values, or node names — hyphens are parsed as relation arrow tokens and cause parse errors. Use underscores: `REQ_001` not `REQ-001`, `auth_service` not `auth-service`
- `text:` field is **plain text only** — no `<br/>`, HTML tags, or special characters; keep to one concise sentence

---

## `C4Context` / `C4Container` / `C4Component`

- Hub-and-spoke patterns cause arrows to route through other nodes. Add `UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")` immediately after the `title` line to spread elements out
- If arrow crossings persist after tuning, split into two diagrams (users→system, system→external)

---

## `erDiagram`

- Relationship labels must be in quotes: `USER ||--o{ ORDER : "places"` — missing quotes cause parse errors

---

## `gantt`

- `dateFormat` must be the first line inside the `gantt` block, before any `section` or task
- Task IDs used in `after X` dependencies must be defined in the same diagram

---

## `requirementDiagram` + `classDiagram` (classDef colors)

- These diagram types do not support the Material Design `classDef` color system — leave nodes unstyled and rely on the theme defaults
