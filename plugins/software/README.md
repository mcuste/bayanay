# Software Plugin

Language-agnostic software architecture skills — ADRs, C4 diagrams, RFCs, and a unified implement command.

---

## Skills

### `/adr`

Drafts or updates Architecture Decision Records. One decision per ADR, immutable once accepted — reverse by writing a new superseding ADR. Auto-detects your ADR directory, validates scope (rejects non-architectural decisions), and self-reviews against 16 quality rules before presenting.

### `/c4`

Drafts or updates C4 architecture diagrams at three levels as Mermaid diagrams:

- **Level 1 — System Context:** Technology-agnostic stakeholder view. Always generated first.
- **Level 2 — Container:** Shows deployable units with technology choices. Requires multiple containers.
- **Level 3 — Component:** Internal structure of a single container. Only on explicit request.

Derives all diagrams from actual codebase analysis (Cargo.toml, Dockerfile, docker-compose, k8s manifests, terraform). Never invents components.

### `/rfc`

Drafts or updates RFCs (Requests for Change) — async technical proposals for architecture changes or revisiting ADRs. Manages the full lifecycle: Draft, In Review, Accepted/Rejected, Implemented/Superseded. Requires at least 2 alternatives with specific rejection reasoning. After acceptance, creates ADRs and updates C4 diagrams.

### `/implement`

Language-agnostic dispatcher. Detects the project language (via Cargo.toml, pyproject.toml, source files) and delegates to the appropriate language-specific implement skill (`rust-implement`, `python-implement`).
