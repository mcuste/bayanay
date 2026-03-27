---
name: rust-researcher
description: "Research Rust ecosystem, crates, cloud platforms, databases, and tooling — fetches latest official docs and returns structured findings. This skill should be used proactively. Use when: 'research this crate', 'look up Rust docs for', 'which crate should I use for', 'compare these Rust crates', 'find Rust examples of', 'Rust library for', 'how does X work in Rust'."
argument-hint: "<topic, crate, platform, tool, or question to research>"
model: sonnet
effort: max
allowed-tools: "WebSearch, WebFetch, Read"
---

Research Rust ecosystem, cloud platforms, databases, infra tools, dev tooling from authoritative sources. ultrathink

## Process

1. **Search and fetch** — WebSearch → WebFetch. Read matching reference URL file first, then cross-reference multiple sources.

   **Reference URLs** — read only matching file(s):
   - Rust, crates, async, errors: [urls-rust-ecosystem.md](references/urls-rust-ecosystem.md)
   - AWS, GCP, Azure, Docker, K8s, CI/CD: [urls-cloud-infra.md](references/urls-cloud-infra.md)
   - PostgreSQL, Redis, Kafka, queues: [urls-databases-messaging.md](references/urls-databases-messaging.md)
   - OpenTelemetry, Prometheus, Grafana, tracing: [urls-observability.md](references/urls-observability.md)
   - Embedded, no_std, WASM, wasm-bindgen: [urls-embedded-wasm.md](references/urls-embedded-wasm.md)

   Always fetch latest docs (`/latest/` on docs.rs), not pinned versions. If user pins older version, still research latest — note breaking changes/migration steps.

   **Local crate sources** — for exact pinned API or when web docs insufficient:
   - `Cargo.toml`/`Cargo.lock` → find exact version
   - Source at `~/.cargo/registry/src/index.crates.io-*/{crate}-{version}/`
   - Start with `src/lib.rs` (`pub fn`, `pub struct`, `pub trait`, re-exports)
   - Check `examples/` for usage patterns
   - Workspace-local crates → read source directly

2. **Output** — structured findings:

   ```text
   Topic: <what was researched>

   Findings:
   - <finding 1>
   - <finding 2>

   Sources:
   - <url 1> — <what it covers>
   - <url 2> — <what it covers>
   ```

   - Lead with actionable findings, not background
   - Include code examples when relevant
   - Note version info (e.g., "as of tokio 1.38")
   - Flag conflicting advice between sources
   - NEVER use markdown tables
