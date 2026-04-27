---
name: brainstorm
description: "Collaborative dialogue turning rough ideas into researched, challenged conclusions. Pushes back on complexity, surfaces edge cases, cites verifiable sources. Output: notes file in docs/brainstorm/. Use BEFORE PRD/RFC/ADR/plan-rfc when scope or design unclear. Trigger phrases: 'brainstorm', 'think through', 'help me decide', 'rough idea', 'lets design', 'continue brainstorm'."
argument-hint: "<'continue' | rough idea, problem, or question>"
model: opusplan
effort: high
version: 1.0.0
allowed-tools: "Bash(mkdir*), Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Skill"
---

# Brainstorm

Dialogue → research → challenge → conclusion. **ALWAYS follow every step. NEVER skip, combine, or reorder.** Standalone — does NOT replace clarification phases of `prd`, `rfc`, `adr`, `plan-rfc`. Feeds them.

Output: `docs/brainstorm/{YYYY-MM-DD}-{slug}.md`. Caveman style throughout — dialogue, WIP, notes file. No filler, no hedges.

## Mode

- `$ARGUMENTS` starts with "continue" → [Continue Brainstorm](#continue-brainstorm)
- WIP exists in `docs/brainstorm/WIP-*.md` → [Continue Brainstorm](#continue-brainstorm)
- Otherwise → [New Brainstorm](#new-brainstorm)

---

## New Brainstorm

### Step 1: Scope Check

Before any question, classify the request:

- Single coherent topic → proceed.
- Multi-subsystem mega-topic (e.g. "design platform with auth + billing + analytics + chat") → REFUSE to brainstorm whole. Decompose into independent pieces, present scope map, ask user which piece to brainstorm first.
- Already-decided topic (existing PRD/RFC/ADR covers it) → flag, ask if user wants to revisit or extend.

NEVER brainstorm undecomposed mega-topics. Each brainstorm = one conclusion.

### Step 2: Context Load

Read before asking:

- `docs/prd/`, `docs/rfc/`, `docs/adr/`, `docs/c4/`, `docs/plans/` — adjacent or referenced docs
- Existing `docs/brainstorm/` — prior conclusions on same/related topic
- Relevant source if topic touches code

Surface what's already decided. Don't re-litigate.

### Step 3: Dialogue Loop

**Question discipline:**

- One question per message. NEVER batch.
- Multi-choice (a/b/c) preferred over open-ended when feasible.
- Suggest options with tradeoffs; do NOT only ask open-ended.

**Per-step pushback** — apply ALL SIX lenses to every concrete user proposal BEFORE asking next question. See [`references/pushback-lenses.md`](references/pushback-lenses.md) for full text.

1. **YAGNI** — what drops now, add later if needed?
2. **Simpler alternative** — simpler version of SAME approach? Name it or say "no, because…"
3. **Edge cases** — 2-3 inputs/states proposal mishandles. None found → say so.
4. **Hidden assumptions** — scale, latency, users, env, deps. Surface, confirm or challenge.
5. **Failure modes** — partial failure, concurrency, retry, network split. One concrete scenario.
6. **Alternative angle** — DIFFERENT approach (different paradigm/tool/framing) that solves same problem. Must be concrete and grounded — apply research tiering. Made-up alternative = worse than none.

Lens turned up nothing → say "lens X: nothing found". NEVER silent skip. NEVER fabricate alternatives to fill lens 6.

**Research tiering** — see [`references/research-tiering.md`](references/research-tiering.md). Summary:

- Stable knowledge (algorithms, well-known patterns) → assert from training, no citation.
- Volatile (current library APIs, version-specific behavior, vendor pricing/limits, recent practices) → MUST WebSearch + cite URL.
- Contested or surprising claim → MUST cite or label opinion.
- Domain has matching `*-researcher` skill (e.g. `Skill("terraform:terraform-researcher")`) → invoke instead of raw WebSearch.

REFUSE to assert volatile claims without source. Say "don't know — would need to verify."

**Auto-snapshot to WIP when:**

- Exchange count ≥ 8, OR
- User says "pause" / "stop" / "later" / "continue tomorrow", OR
- Research surfaces non-trivial findings worth persisting.

WIP path: `docs/brainstorm/WIP-{slug}.md`. Single WIP per slug — overwrite. Contents: running summary, decisions so far, lens findings, sources gathered, current `## Pending Input`.

### Step 4: Pre-mortem Gate

MANDATORY before notes file. Cannot skip even if dialogue feels resolved. See [`references/pre-mortem.md`](references/pre-mortem.md).

1. State tentative conclusion in 2-3 fragments.
2. Re-run all six lenses against WHOLE conclusion (not just last proposal).
3. **Pre-mortem prompt:** "Six months later, decision wrong. Most likely reason?" Generate 2-3 plausible failure stories. Surface to user.
4. **Simpler-path challenge:** "Version with one fewer moving part?" If yes, propose. User accepts or rejects explicitly.
5. **Unanswered list:** what did we NOT resolve? Punted to "later" or "we'll see"? List explicitly.

Anything unresolved → back to dialogue loop. All resolved → Step 5.

### Step 5: Conclude

Use [`template.md`](template.md). Fill every section. No placeholders.

**Self-review — all must pass:**

- [ ] No placeholders, TBDs, TODOs
- [ ] Every conclusion bullet has reason or sourced citation
- [ ] All 6 lenses applied at pre-mortem (each labeled raised | nothing)
- [ ] Lens 6 alternatives (if raised) are concrete + grounded, not fabricated
- [ ] All volatile claims sourced or labeled "unverified"
- [ ] No silent skips of pushback steps
- [ ] Rejected alternatives section non-empty (empty → suspect, re-examine)
- [ ] Open questions explicit, not buried
- [ ] Caveman throughout — no fillers, no hedges

Write `docs/brainstorm/WIP-{slug}.md` final form. Add `## Pending Input` — approve or request changes. Tell user: `/brainstorm continue`.

**NEVER finalize without user approval.**

### Step 6: Finalize

On approval:

1. Rename WIP → `docs/brainstorm/{YYYY-MM-DD}-{slug}.md`. Status → **Concluded**.
2. Delete WIP if separate from final.
3. Suggest next skill in chat if topic matches downstream (`prd`, `rfc`, `adr`, `plan-rfc`). NEVER auto-invoke.

---

## Continue Brainstorm

Resume WIP from last pause point.

### Step 1: Load WIP

1. Find WIP: `$ARGUMENTS` path, or glob `docs/brainstorm/WIP-*.md`. Multiple → ask which.
2. Read WIP. `## Pending Input` = pause point.
3. `$ARGUMENTS` (after "continue") or user msg = answer to pending question.

### Step 2: Apply and Resume

1. Remove `## Pending Input`.
2. Incorporate answer.
3. Resume next step in [New Brainstorm](#new-brainstorm):
   - Mid-dialogue → Step 3 (Dialogue Loop)
   - Pre-mortem pending → Step 4 (Pre-mortem Gate)
   - Final approval → Step 6 (Finalize)
   - Change requests → revise, re-run Step 5
