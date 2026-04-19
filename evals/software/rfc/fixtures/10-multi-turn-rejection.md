<!-- turn: user -->
Write an RFC for replacing PostgreSQL with MongoDB for our user profile service. Profiles are getting more complex with nested preferences, notification settings, and UI customization. The relational model feels forced — we're using JSONB columns for half the fields anyway. This targets implementation and ADR.

<!-- turn: assistant -->
<!-- expected: propose 2-3 approaches, including "keep PostgreSQL with better JSONB usage" as an alternative -->

<!-- turn: user -->
Go with the MongoDB migration approach.

<!-- turn: assistant -->
<!-- expected: full RFC draft, Status: Draft, alternatives include keeping PostgreSQL with JSONB optimization -->

<!-- turn: user -->
After team review, we're rejecting this RFC. The migration risk is too high for the marginal benefit — the team pointed out that our JSONB queries are slow because of missing GIN indexes, not because of PostgreSQL itself. We'll optimize the existing approach instead.

<!-- turn: assistant -->
<!-- expected: add Rejection Reason section, Status: Rejected, change log entry, flag any related RFCs/ADRs -->
