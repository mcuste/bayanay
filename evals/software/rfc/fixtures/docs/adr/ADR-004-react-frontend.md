# ADR-004: React with TypeScript for Frontend

- **Status**: Accepted
- **Date**: 2025-09-10
- **Deciders**: Frontend team, CTO
- **Affects**: All frontend applications

## Context

Starting a new frontend for the customer dashboard. Team has experience across React, Vue, and Angular. Need to standardize on one framework for hiring and code sharing.

## Decision

Use React 18 with TypeScript for all new frontend development. State management via Zustand. Styling with Tailwind CSS. Build tooling with Vite.

## Consequences

### Positive
- Largest talent pool for hiring
- Rich ecosystem of component libraries and tooling
- TypeScript catches bugs at compile time

### Negative
- React's flexibility means more architectural decisions per project
- Bundle size larger than Preact/Svelte alternatives

## Alternatives Considered

- **Vue 3** — rejected: smaller hiring pool in our market, fewer enterprise component libraries
- **Angular** — rejected: too opinionated for our small team, heavier learning curve
