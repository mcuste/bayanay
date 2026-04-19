# PRD-001: Marketplace Search Overhaul

- **ID**: PRD-001
- **Status**: Draft
- **Author**: —
- **Created**: 2026-04-19
- **Last Updated**: 2026-04-19

## Problem

Search on the freelancer marketplace returns irrelevant results and lacks basic filtering, driving 60% of users to abandon search after the first page. Current search matches keywords against titles only, ignoring skills, descriptions, availability, rate, and timezone. With 50k freelancer profiles and 10k active job postings, users can't efficiently find what they need. Clients waste time scrolling through irrelevant profiles; freelancers miss matching gigs because keyword matching doesn't surface them. This directly impacts marketplace liquidity — unmatched supply and demand.

## Personas & Use Cases

- **Hiring Client** (posts jobs, searches for freelancers): Needs to find freelancers by skill, availability, rate range, and timezone overlap. Currently searches by title keywords, gets irrelevant results, and resorts to posting a job and waiting for applications — slow and passive.
- **Freelancer** (seeks gigs, maintains a profile): Needs to discover relevant job postings matching their skills, rate expectations, and schedule. Currently misses matching gigs because search doesn't factor in skills beyond the job title. Also needs their profile to surface when clients search — findability directly impacts income.
- **Marketplace Operator** (internal, monitors match quality): Needs to understand search effectiveness — what queries return poor results, where supply/demand gaps exist. Currently has no visibility into search quality metrics.

## Goals & Scope

- **Must have**: Search across titles, descriptions, and skills (not just titles). Filter by availability, hourly rate range, and timezone. Relevance ranking that considers query match strength across multiple fields. Separate search experiences optimized for "find a freelancer" and "find a gig" — they have different attributes and intent. Results show why a result matched (matched skill highlighted, rate in range).
- **Should have**: Saved search filters so returning users don't reconfigure every time. Sort options (relevance, rate low-to-high, rate high-to-low, most recently active). Suggested filters based on the query (e.g., searching "React developer" suggests filtering by "JavaScript" skill).
- **Non-goals**: AI-powered matching or recommendation engine — separate initiative, this PRD focuses on making manual search effective. Freelancer profile redesign — search improves discovery, not the profile page itself. Real-time availability calendars — availability is a coarse filter (available now / available within 2 weeks / not available), not a booking system.

## User Stories

- As a **Hiring Client**, I want to search for freelancers by skill and filter by hourly rate and timezone so that I see only candidates who match my budget and working hours.
  - **Acceptance**: Searching "React" with filters rate $50–$100/hr and timezone UTC-5 to UTC-8 returns only freelancers with React as a skill, rate within range, and timezone within range. Results ranked by relevance, not alphabetical.
  - **Scenario**: Client searches "data visualization," filters to $60–$90/hr, timezone "Americas." Gets 23 results. Each result card shows matched skills highlighted (D3.js, Tableau), hourly rate, availability status, and timezone. Client refines to "available within 1 week" — results narrow to 8.

- As a **Freelancer**, I want to search for gigs matching my skills and filter by rate so that I don't waste time applying to jobs below my rate or outside my expertise.
  - **Acceptance**: Gig search matches against skills listed in the freelancer's profile, plus free-text query. Filter by minimum rate, project duration, and remote/on-site.
  - **Scenario**: Freelancer with skills [Python, Machine Learning, NLP] searches "ML engineer." Results show gigs ranked by skill overlap — a gig requiring Python + ML + NLP ranks higher than one requiring only Python. Freelancer filters to ≥ $80/hr and sees 12 relevant postings. Each result shows which of their skills matched.

- As a **Hiring Client**, I want search results to show why each freelancer matched my query so that I can quickly assess relevance without opening every profile.
  - **Acceptance**: Each search result card highlights which skills, description keywords, or attributes matched the query and active filters.
  - **Scenario**: Client searches "mobile developer iOS." Result cards show matched skills (Swift, iOS, Mobile Development) highlighted. A freelancer whose title says "Software Engineer" but whose skills include iOS and Swift still appears — unlike today where title-only matching would miss them.

## Behavioral Boundaries

- **Empty results**: When no results match current filters, show the active filters with a suggestion to broaden (e.g., "No freelancers match all filters. 15 results available if you remove the timezone filter"). Never show a blank page.
- **Query length**: Maximum query length 200 characters. Beyond that, truncate with notice.
- **Filter combinations**: All filters are combinable (AND logic). If a filter combination returns 0 results, show the count before applying the last filter so users know which filter eliminated results.
- **Result set size**: Display 20 results per page. Maximum 50 pages (1,000 results) — queries returning more than 1,000 matches should be prompted to narrow with filters.

## Non-Functional Requirements

- **Performance**: Search results return in < 500ms (p95) for any query/filter combination across the full 50k profile + 10k posting dataset.
- **Scalability**: Index and search architecture should handle 10x data growth (500k profiles) without degrading below the 500ms target.
- **Reliability**: Search must be available 99.9% of the time. If the search index is stale or unavailable, show a degraded experience with a notice rather than an error page.

## Risks & Open Questions

- **Risk**: Freelancer profiles have inconsistent skill tagging — some list "React," others "ReactJS," others mention it only in description — likelihood: H — mitigation: normalize skills against a taxonomy during indexing; match synonyms.
- **Risk**: Relevance ranking may feel arbitrary to users initially — likelihood: M — mitigation: show match explanations on result cards; iterate ranking based on click-through data post-launch.
- **Dependency**: Freelancer availability data — assumes profiles have a machine-readable availability status. If this is currently free-text only, a data cleanup or profile update flow is prerequisite.
- [ ] Should search results be personalized (e.g., boosting freelancers the client has hired before, or gigs from repeat clients)?
- [ ] How should search handle freelancers who haven't updated their profile in > 6 months? Demote in ranking? Flag as potentially stale?
- [ ] Do we need separate search indexes for freelancers and gigs, or a unified index with type filtering?

## Success Metrics

- Search abandonment rate drops from 60% to below 25% within 8 weeks of launch
- Search-to-hire conversion rate (client searches → client sends an offer) increases by 30%
- Freelancer gig application rate from search results increases by 40%
- Average filters used per search session > 1.5 (indicates filters are discoverable and useful)
