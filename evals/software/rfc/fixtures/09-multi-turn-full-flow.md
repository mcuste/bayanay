<!-- turn: user -->
Draft an RFC for migrating our auth system from session-based to JWT tokens. We use Express + PostgreSQL. About 50 API endpoints check auth. Sessions are stored in PostgreSQL via connect-pg-simple. We want stateless auth for horizontal scaling — right now every request hits the sessions table and it's becoming a bottleneck at 10k concurrent users. This targets implementation and ADR.

<!-- turn: assistant -->
<!-- expected: propose 2-3 approaches with tradeoffs, recommend one, wait for user pick -->

<!-- turn: user -->
Go with approach 2, the hybrid migration with feature flag. I like that we don't have to do a big-bang cutover.

<!-- turn: assistant -->
<!-- expected: full RFC draft following template, Status: Draft, >=2 alternatives with specific rejection reasoning, Goals and Non-Goals filled, no placeholders -->

<!-- turn: user -->
Looks good. Two changes: add a non-goal about not implementing refresh token rotation in this RFC (we'll do that separately), and mention in open questions whether we need to invalidate existing sessions during migration or let them expire naturally. Then write it.

<!-- turn: assistant -->
<!-- expected: apply both changes, write to docs/rfc/RFC-001-auth-jwt-migration.md, Status: In Review, change log entry -->
