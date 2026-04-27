---
name: ascii-diagram
description: "Use proactively to drop an inline ASCII/Unicode sketch into any explanatory answer where layout, structure, or sequence aids comprehension. Fire on requests to explain, describe, walk through, illustrate, model, map out, lay out, break down, compare, contrast, or teach — covering systems, processes, architectures, workflows, pipelines, hierarchies, trees, relationships, sequences, state machines, lifecycles, layered stacks, dependency chains, request/response flows, call sequences, data shapes, schemas, and timelines. Also fire on phrasings: 'how does X work', 'what does X look like', 'difference between', 'X vs Y', 'help me understand', 'show me', 'walk me through', 'explain this code', 'sketch', 'visualize', 'draw', 'diagram', 'in text', 'in ascii', 'inline', 'quick', 'ELI5'. Ephemeral — output is a fenced text block in chat, no rendering, no file save. Prefer this over the `diagram` (Mermaid) skill for any in-chat explanation; use Mermaid only when the user explicitly wants a polished, saved, shared, or documentation-grade diagram."
argument-hint: "<concept, structure, or flow to sketch>"
effort: medium
version: 1.0.0
---

Quick ASCII/Unicode sketches inline in chat. Output is a fenced text block — nothing more.

## 1 — When to use

Reach for it when:

- Prose forces the reader to mentally reconstruct a layout
- Comparing 2+ structures side-by-side
- Showing direction, sequence, or hierarchy
- Concept has spatial meaning (stack, tree, flow, timeline)

Skip if:

- Prose conveys it cleanly — don't decorate
- Diagram needs >10 nodes, curves, proportional widths, or icons → use `diagram` skill (Mermaid)
- Output will be saved as documentation → use `diagram` skill

## 2 — Charset

| Purpose         | Chars                                  |
|-----------------|----------------------------------------|
| Box corners     | `┌ ┐ └ ┘`                              |
| Box edges       | `─ │`                                  |
| Tees / cross    | `├ ┤ ┬ ┴ ┼`                            |
| Rounded corners | `╭ ╮ ╰ ╯`                              |
| Arrows          | `→ ← ↑ ↓ ▶ ◀ ▲ ▼ ↔`                    |
| Dashed          | `┄ ┆ ╌ ╎`                              |
| Double (rare)   | `╔ ═ ╗ ║ ╚ ╝`                          |
| Bar fill        | `▇ ▆ ▅ ▄ ▃ ▂ ▁`                        |

Use single-line `─│` by default. Double `═║` only for emphasizing one boundary. Rounded `╭╮╰╯` for a softer feel — pick one style per diagram, don't mix.

## 3 — Pattern catalog

Only patterns that read cleanly in ASCII. If your subject doesn't fit one of these, prose may be the right answer — or switch to Mermaid.

### Flow / process / architecture

Boxes + directional arrows + diamond-free decisions (use a labeled split).

```
┌────────┐    ┌──────────┐    ┌────────┐
│ Client │───▶│ Service  │───▶│   DB   │
└────────┘    └────┬─────┘    └────────┘
                   │ cache hit?
                ┌──┴──┐
              yes    no
                ▼     ▼
            [return] [fetch]
```

### Hierarchy / tree

File-tree style. Use `├──` for siblings, `└──` for last, `│` to continue parent line.

```
root
├── child-a
│   ├── grand-1
│   └── grand-2
└── child-b
    └── grand-3
```

### Sequence

Vertical lifelines, horizontal messages. Right arrow = call, left arrow = return.

```
Client       Server        DB
  │            │            │
  │  request   │            │
  │ ─────────▶ │            │
  │            │   query    │
  │            │ ─────────▶ │
  │            │ ◀───────── │
  │  response  │            │
  │ ◀────────  │            │
```

### State machine

Rounded/parenthesized states + labeled transitions.

```
( idle ) ── start ──▶ ( running ) ── done ──▶ ( finished )
                          │
                       error
                          ▼
                      ( failed )
```

### Table (compare / schema / ER)

Use for side-by-side comparison or simple entity fields. Add connecting lines between two tables for ER-style relationships.

```
┌─────────┬───────┬───────────┐
│ Option  │ Speed │ Tradeoff  │
├─────────┼───────┼───────────┤
│ A       │ fast  │ memory    │
│ B       │ slow  │ accurate  │
└─────────┴───────┴───────────┘
```

### Layered stack

Vertical bands, top-to-bottom. Good for protocol stacks, abstraction layers, dependency depth.

```
┌──────────────┐
│ Application  │
├──────────────┤
│  Framework   │
├──────────────┤
│   Runtime    │
├──────────────┤
│      OS      │
└──────────────┘
```

### Timeline

Horizontal axis with event markers. Labels below or above the line, never both.

```
──●──────────●─────────●─────▶
  │          │         │
launch     v2.0      sunset
```

### Horizontal bar (optional)

Only when comparing magnitudes of 3–6 items. Skip for continuous data.

```
A │ ▇▇▇▇▇▇▇          35
B │ ▇▇▇▇▇▇▇▇▇▇▇▇     62
C │ ▇▇▇              18
```

## 4 — Sizing & layout

- Width ≤ 80 chars — fits chat without wrapping
- Nodes ≤ 10 — else split, or switch to Mermaid
- Align with spaces, never tabs
- Short labels: 1–2 words inside boxes; wrap to a second line if needed
- One arrow per logical edge — don't chain `A ──▶ B ──▶ C` through a box; route around
- If labels collide or arrows must cross, redraw — don't ship a tangled sketch

## 5 — Output

Drop the diagram in a fenced code block right where it aids the explanation. No title, no caption, no file save:

````
```
┌──────┐    ┌──────┐
│  A   │───▶│  B   │
└──────┘    └──────┘
```
````

Then carry on with the prose. The diagram is a visual aid, not the answer.
