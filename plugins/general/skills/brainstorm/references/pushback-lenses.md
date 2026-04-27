# Pushback Lenses

Apply ALL SIX to every concrete user proposal before asking next question. Caveman style. Never silent-skip.

Pushback ≠ alternatives. Lenses 1, 3, 4, 5 = find problems. Lens 2 = simpler version of same approach. Lens 6 = different approach entirely. Both kinds matter — surface problems AND propose paths.

Output format per lens:

- `lens X: raised — {finding}`, OR
- `lens X: nothing found`

Both states explicit. No skipped lenses.

---

## 1. YAGNI

What part drops now, add later if needed?

Look for: extra fields, optional configs, premature abstractions, "just in case" features, multi-format support, plugin systems, generic frameworks where one concrete instance suffices.

Examples:

- raised — "auth system supports OIDC, SAML, LDAP. drop SAML and LDAP. add when first paying customer asks."
- nothing found — "proposal already minimal. each piece serves stated requirement."

Rule: name the SPECIFIC item. "feels overscoped" = bad. "the retry config knob with 4 fields" = good.

## 2. Simpler Alternative

Simpler version of SAME approach? Existing tool, simpler data model, fewer moving parts. Same shape, less of it.

Look for: rolling own auth vs library, custom queue vs SQS/Redis, microservices vs monolith, distributed cache vs in-memory, custom framework vs Postgres feature.

Examples:

- raised — "instead of new event bus, use Postgres LISTEN/NOTIFY. existing infra, no new dep."
- nothing found — "checked: no managed service fits. custom is simpler than alternatives."

Rule: name the alternative concretely or say "no, because…". Vague "could be simpler" = bad. For DIFFERENT approach (not simpler), use lens 6.

## 3. Edge Cases

2-3 inputs/states proposal mishandles.

Look for: empty input, max-size input, concurrent input, malformed input, unicode/encoding, timezone boundaries, leap seconds/years, off-by-one, partial state, replay, duplicate, out-of-order events.

Examples:

- raised — "(1) empty list breaks `head`, (2) duplicate IDs in batch, (3) clock skew between writers."
- nothing found — "walked through input space. proposal handles: empty, max, concurrent, malformed."

Rule: each edge case = ACTUAL failure scenario. "might have edge cases" = bad. "if user submits empty array, code crashes at line X" = good.

## 4. Hidden Assumptions

What does proposal assume about scale, latency, users, env, deps?

Look for: assumed throughput, assumed latency budget, assumed user trust level, assumed availability of dep, assumed schema stability, assumed single-region, assumed always-online, assumed sync/async semantics.

Examples:

- raised — "assumes <100 RPS. if hits 10k RPS, in-process cache becomes bottleneck."
- raised — "assumes Redis available. no fallback for outage."
- nothing found — "assumptions surfaced and confirmed: <1k users, single region, eventual consistency OK."

Rule: surface assumption AS assumption. user confirms or challenges. unstated = invisible risk.

## 5. Failure Modes

What breaks under partial failure, concurrency, retry, network split?

Look for: half-committed state, double-write, lost write, duplicate processing, deadlock, livelock, cascading retry, thundering herd, split-brain.

Examples:

- raised — "if step 2 fails after step 1, DB has half-state. no compensating action defined."
- raised — "retry without idempotency key → duplicate charges."
- nothing found — "walked failure tree: each step has explicit handling or accepted-risk note."

Rule: ONE concrete scenario. "could fail in distributed setting" = bad. "if leader dies between commit and ack, follower replays last op = duplicate" = good.

## 6. Alternative Angle

DIFFERENT approach to same problem. Not simpler version — different paradigm, tool, framing. May be equal or more complex but better fit. Generative, not corrective.

Look for:

- different architectural style — event-driven vs request/response, push vs pull, stream vs batch, sync vs async
- different storage paradigm — relational vs document vs KV vs columnar vs graph
- different deployment model — serverless vs container vs VM vs edge
- different tool/library/managed service occupying same niche
- problem reframing — is stated problem the real problem? does different question dissolve it?

Examples:

- raised — "alternative: instead of polling job queue, webhook callbacks. trades infra (need public endpoint) for latency (push not poll). different shape, solves same coordination problem. [verify current webhook delivery guarantees on platform if relying on it]"
- raised — "reframe: stated problem 'how to scale write-heavy DB'. alternative framing: 'must writes be synchronous?' async write-behind cache changes shape entirely. user confirms latency budget first."
- raised — "alt tool: ClickHouse for analytics workload instead of indexed Postgres. column-store fits scan-heavy queries. trades operational complexity (new system) for query performance ([cite version-specific perf claims if surfaced])."
- nothing found — "considered: event-driven, batch, streaming. each rejected because {reason}. request/response remains best fit for stated constraints."

Rules — ALL must hold for `raised`:

1. Solves SAME underlying problem (not adjacent / different problem).
2. Concrete — named tool, pattern, paradigm. Not "could try something else".
3. Grounded — apply [research tiering](research-tiering.md). Volatile claims (current capabilities, pricing, ecosystem state) MUST cite. Stable patterns (CQRS, event sourcing, CRDT) assert from training OK.
4. Tradeoff named — what gets better, what gets worse vs original. No free-lunch alternatives.

If grounding requires research and research not done → say "alt direction X may apply, would need to verify {specific thing}". DO NOT invent specifics.

Made-up alternatives are WORSE than no alternative — they pollute the design space with phantom options. Say "nothing found" before fabricating.

Difference from lens 2:

- Lens 2: same approach, less of it (drop Redis cache from stack)
- Lens 6: different approach (replace synchronous queue with event stream)

Both can fire on same proposal. Both can return nothing.

---

## When User Pushes Back On Lens

User says "that's overthinking" or "doesn't matter":

- ACCEPT if: scope or constraints make lens irrelevant (e.g. internal tool, single user, no concurrency).
- PUSH BACK if: user dismissing without engaging with specific finding.

Record outcome in WIP — "dismissed because {reason}" or "addressed by {change}". NEVER drop silently.
