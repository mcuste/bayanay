# Pre-mortem Gate

Mandatory before notes file. Catches what slipped through per-step lenses. Cannot skip even if dialogue feels resolved.

## Procedure

### 1. State Tentative Conclusion

2-3 fragments. Caveman.

Example:

> Tentative: use Postgres LISTEN/NOTIFY for event bus. single-region. <1k events/sec. fallback to polling on connection drop.

### 2. Re-run All Six Lenses Against Whole Conclusion

Different pass — catches conclusion-level issues missed at per-proposal level. Lens 6 especially valuable here: at conclusion stage, alternative angle may reveal whole approach is wrong shape.

Format same as dialogue lenses (`raised — {finding}` | `nothing found`). Surface to user.

### 3. Pre-mortem Prompt

Ask: "Six months later, this decision turned out wrong. Most likely reason?"

Generate 2-3 plausible failure stories. Concrete, named. Surface to user.

Examples:

- "Traffic 50x'd. LISTEN/NOTIFY didn't scale past 5k/sec. Migrated to Kafka in panic."
- "Multi-region requirement appeared in Q3. LISTEN/NOTIFY single-region by design. Rewrite."
- "Connection drops more frequent than expected. Polling fallback became primary. Original design wasted."

User responds: addresses each, accepts as risk, or revises conclusion.

### 4. Simpler-path Challenge

Ask: "Version of conclusion with one fewer moving part / option / integration?"

If yes, propose. If no, say "checked — already minimal."

User explicitly accepts simpler version OR explicitly rejects with reason.

Example:

- Original: "Postgres LISTEN/NOTIFY + Redis cache + polling fallback."
- Simpler: "Postgres LISTEN/NOTIFY + polling fallback. Drop Redis — re-add if measurable cache need."
- User decides.

### 5. Unanswered List

What did we NOT resolve?

Look for:

- "we'll figure that out later"
- "depends on X" where X never confirmed
- assumed inputs/outputs never specified
- error handling never discussed
- monitoring / observability never discussed
- migration path never discussed (if replacing existing)

List explicitly. Each item → either:

- Move to `## Open / deferred` in notes file with revisit trigger, OR
- Address now, update conclusion.

## Resolution Gate

ALL must hold before writing notes file:

- [ ] Conclusion stated and re-lensed
- [ ] 2-3 failure stories generated, user responded to each
- [ ] Simpler-path proposed (or "already minimal" stated)
- [ ] Unanswered list non-trivially examined
- [ ] User explicitly approves moving to notes file

Anything unresolved → back to dialogue loop. NEVER write notes file with unresolved gate items.

## Bad Patterns

- Generating generic failure stories ("system could break") → useless. Need named, concrete, plausible.
- Skipping simpler-path because conclusion "feels right" → that's exactly when to challenge.
- Hiding unanswered items as "minor follow-ups" → list them. Punted is fine if explicit.
- Asking user to approve before lens re-run → no. Run lenses FIRST, then ask.
