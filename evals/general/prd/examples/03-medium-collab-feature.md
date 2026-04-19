# PRD-001: Real-Time Collaboration for Document Editor

- **ID**: PRD-001
- **Status**: Draft
- **Author**: —
- **Created**: 2026-04-19
- **Last Updated**: 2026-04-19

## Problem

Users cannot edit documents simultaneously. Teams of 3–8 people email documents back and forth, creating version conflicts and lost work. 40 support tickets in the last quarter specifically mention "can't edit at the same time" or "lost my changes." The current single-editor model forces teams into serial workflows — one person edits while others wait, or multiple people edit offline copies that must be manually reconciled. With 2,000 active users across small teams, this is the top friction point in the product.

## Personas & Use Cases

- **Team Contributor** (writes and edits documents daily): Needs to open a document and start editing alongside teammates without coordination overhead. Currently waits for others to finish or risks overwriting their changes.
- **Team Lead** (reviews and finalizes documents): Needs to see who's working on a document and what they're changing in real time. Currently receives multiple email versions and manually merges edits.
- **Solo Author** (works independently on personal documents): Collaboration features should not degrade the single-user editing experience. No forced awareness of collaboration when working alone.

## Goals & Scope

- **Must have**: Multiple users editing the same document simultaneously. Presence indicators showing who is currently viewing or editing. Live cursors showing where each collaborator is working. Automatic conflict resolution — concurrent edits never result in lost content. Changes from other users appear within 1 second.
- **Should have**: User avatars/names on cursors and presence indicators. Visual distinction between viewing and actively editing. Ability to see how many collaborators are in a document before opening it.
- **Non-goals**: Comments and suggestions workflow — separate feature, different interaction model. Offline editing with sync — requires fundamentally different conflict resolution strategy; revisit post-launch. Version history / undo across users — important but independent scope; current per-user undo should not regress. Permissions changes — existing document sharing and access control remain unchanged.

## User Stories

- As a **Team Contributor**, I want to open a document that a teammate is already editing so that we can both work on it at the same time without overwriting each other's changes.
  - **Acceptance**: Two users can edit the same paragraph concurrently. Both users' changes are preserved in the final document. No "document locked" errors.
  - **Scenario**: Alice opens the Q3 report to update the metrics section. Bob opens the same document to rewrite the introduction. Alice sees Bob's avatar and cursor in the introduction. Both type simultaneously. Alice's metrics edits and Bob's intro rewrite both appear in real time. Neither user loses any content.

- As a **Team Lead**, I want to see who is currently in a document so that I know whether to jump in now or wait.
  - **Acceptance**: Presence indicators show avatars of all users currently viewing or editing. Indicators update within 5 seconds of a user joining or leaving.
  - **Scenario**: Carol opens the project proposal and sees two presence indicators — Dave (editing, cursor visible in section 2) and Eve (viewing, no cursor). Carol decides to edit section 4 since nobody is working there. When Dave closes the document, his presence indicator disappears within 5 seconds.

- As a **Solo Author**, I want my editing experience to remain fast and uncluttered when I'm the only person in a document.
  - **Acceptance**: No visible collaboration UI when the user is the only one in the document. Editor performance (keystroke latency, load time) does not regress compared to the current single-user experience.
  - **Scenario**: Frank opens his personal notes document. No presence indicators, no cursors — the editor looks and feels identical to today. Keystroke-to-render latency stays under 50ms.

## Behavioral Boundaries

- **Maximum concurrent editors**: Up to 10 simultaneous editors per document. Beyond 10, additional users can view in read-only mode with a message: "This document has 10 active editors. You can view changes in real time and will be able to edit when someone leaves."
- **Presence staleness**: If a user's connection drops, their presence indicator remains for 30 seconds before being removed. If they reconnect within 30 seconds, no visible interruption. After 30 seconds, their cursor and presence disappear.
- **Conflict resolution visibility**: When two users edit the same word simultaneously, both edits are preserved (e.g., appended or interleaved at character level). The system never silently discards content. Users can undo their own changes but not others'.
- **Network interruption**: If a user loses connectivity, their local edits are buffered. A "reconnecting…" indicator appears after 3 seconds. On reconnection, buffered edits sync automatically. If disconnected for > 2 minutes, the user sees "You were disconnected. Your changes have been saved and synced."

## Non-Functional Requirements

- **Performance**: Remote changes visible within 1 second of being made (p95). Local keystroke-to-render latency < 50ms, unchanged from current baseline. Document load time increase < 500ms compared to current single-user load.
- **Reliability**: No data loss under any concurrent editing scenario. Collaboration service availability ≥ 99.9%. If collaboration service is unavailable, editor falls back to single-user mode gracefully — users can still edit, they just don't see others.
- **Scalability**: Support 2,000 active users with up to 200 concurrent collaborative sessions (10% of users editing at peak).
- **Security**: Collaboration channels enforce the same document-level permissions as the existing access control system. No user can see cursor positions or content of a document they don't have access to.

## Risks & Open Questions

- **Risk**: Existing REST API architecture may introduce latency for real-time updates — likelihood: H — mitigation: collaboration features will likely require a persistent connection layer alongside the existing REST API. Architecture details belong in the technical design.
- **Risk**: Conflict resolution behavior may surprise users accustomed to "last write wins" — likelihood: M — mitigation: subtle visual feedback when concurrent edits merge (brief highlight on merged text). User testing with 2–3 teams before general rollout.
- **Dependency**: The existing PostgreSQL backend must support the write throughput of concurrent collaborative sessions — capacity assessment needed.
- [ ] Should presence show across all documents (e.g., in a document list view) or only when a document is open?
- [ ] How should collaboration interact with existing auto-save? Currently auto-save triggers every 30 seconds — real-time collaboration implies continuous saving.
- [ ] Do users need the ability to "follow" another user's cursor (scroll to where they're working)?

## Success Metrics

- Adoption: ≥ 50% of teams (teams with 3+ members) use simultaneous editing within 6 weeks of launch
- Support reduction: "Lost my changes" and "can't edit at same time" tickets drop by 80% within one quarter
- Performance: p95 remote change latency < 1 second measured over first month
- Retention: No increase in churn rate among existing users post-launch (collaboration must not degrade the experience)
