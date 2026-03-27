# General Plugin

General-purpose utilities — Mermaid diagrams, product requirements documents, and compressed output mode.

---

## Skills

### `/diagram`

Generates Mermaid diagrams for any system, process, workflow, data model, or concept. Supports 20 diagram types: flowcharts, sequence, state, ER, class, Gantt, pie, mindmap, timeline, quadrant, sankey, git graph, C4, block, architecture, packet, kanban, XY chart, requirement, and journey.

All diagrams use a Material Design color system with semantic meaning:
- **Blue** — default nodes, main path
- **Green** — success states, completions
- **Pink** — errors, failures, warnings
- **Purple** — external systems, third-party services
- **Yellow** — notes, pending states
- **Grey** — disabled, deprecated

### `/prd`

Drafts or updates Product Requirements Documents. Produces structured documents covering: problem statement, context, personas, goals, scope, user stories, non-functional requirements, assumptions, risks, success metrics, and references.

Stays in the problem space — no technical detail, no schemas, no framework choices. Validates output against 32 quality rules across completeness, clarity, feasibility, and consistency.

### `/cavemen`

Ultra-compressed communication mode. Cuts token usage by dropping articles, filler, pleasantries, and hedging while keeping technical terms exact. Code blocks and error quotes stay unchanged.
