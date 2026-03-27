# Testing

## Test Strategy

- [test-tdd-domain] ALWAYS use TDD for domain logic, algorithms, libraries, public APIs, bug fixes, complex state
- [test-no-tdd-ui] NEVER use TDD for UI-heavy code or legacy code without tests (use characterization tests)
- [test-no-trivial] NEVER test trivial getters/simple mappings
- [test-refactor-complex] ALWAYS refactor high-complexity many-collaborator code before testing
- [test-unit-complex] ALWAYS unit test high-complexity few-collaborator code heavily
- [test-integ-collab] ALWAYS integration test low-complexity many-collaborator code

## Integration Tests

- [test-expose-lib] ALWAYS expose through `lib.rs` any logic for integration testing
- [test-mock-unmanaged] ALWAYS mock only unmanaged deps (SMTP, message bus); use real managed deps (app-owned DB)
- [test-mock-edge] ALWAYS mock at outermost edge; mock only types you own
- [test-one-happy-path] ALWAYS prefer one happy path + edge cases unit tests can't reach
- [test-integ-sequential] ALWAYS run integration tests sequentially
- [test-contract-tests-dir] ALWAYS place API contract tests in `tests/`

## External Dependency Testing Tiers

Test at the cheapest tier that covers the risk. Escalate only when a lower tier can't exercise the behavior under test.

- [test-tier-principle] ALWAYS pick the lowest-cost tier that covers the risk — never default to a heavier tier
- [test-tier1-closures] ALWAYS use injected async closures or pure functions as the default (tier 1) — no Docker, no network, instant feedback
- [test-tier2-wiremock] ALWAYS use `wiremock` (tier 2) when testing real HTTP client behavior (headers, retries, error codes) — still in-process, no Docker
- [test-tier3-emulator] ALWAYS use `testcontainers` with service emulators (tier 3) when protocol fidelity matters (gRPC, auth chains, transaction semantics) — requires Docker in CI
- [test-tier4-real] ALWAYS gate real-service tests with `#[ignore]` (tier 4) when no emulator exists — run in dedicated CI job with credentials
- [test-tier-no-skip] NEVER jump to tier 3/4 when tier 1/2 suffices — Docker overhead is not free

## Niche Testing Rules

- [test-track-caller] ALWAYS add `#[track_caller]` on test helper functions containing assertions
- [test-should-panic-msg] ALWAYS use `#[should_panic(expected = "substring")]` over bare `#[should_panic]`
- [test-sans-io] ALWAYS consider Sans-IO for protocol impls; NEVER for simple request/response

## Functional Core, Imperative Shell

- [test-fcis-extract] ALWAYS extract decision logic from async fns into pure `fn(data) -> data + side-effect instructions`
- [test-fcis-shell-thin] ALWAYS keep I/O shell to: read → call pure fn → write — no branching beyond dispatching on pure fn's return
- [test-fcis-decision-enum] ALWAYS use decision enum (`UseCache`, `TryRefresh`, `FullFlow`) when pure fn's output picks which I/O path runs next
- [test-fcis-test-pure] ALWAYS test pure decision fns with plain sync unit tests — no traits, mocks, or async runtime
- [test-fcis-shell-integ] ALWAYS test I/O shell via integration tests (`#[ignore]`) — unit tests OK only if shell has non-trivial orchestration
- [test-fcis-no-pure-io] NEVER apply FCIS to pure I/O pipelines (get→pass→return, no branching) — integration-test directly
- [test-fcis-no-over-enum] NEVER model I/O-dependent recovery/fallback as second decision enum — indirection costs more than it saves; integration-test instead
- [test-cleanup-start] ALWAYS clean up at test start, not teardown
- [test-no-repo-direct] NEVER test repositories directly — only within integration tests
- [test-assert-matches] ALWAYS prefer `assert!(matches!(value, Pattern))` or `assert_matches!` over manual `match` + `panic!`
- [test-tempfile] ALWAYS use `tempfile::TempDir`/`NamedTempFile` over hardcoded paths in tests
- [test-async-await] ALWAYS await properly in async tests
- [test-no-sleep] NEVER sleep in tests — use deterministic sync

## Parameterized & Property Testing

- [test-rstest] ALWAYS use `rstest` for parameterized tests and fixtures
- [test-proptest] ALWAYS use `proptest` for invariants over arbitrary input

## Snapshot Testing

- [test-snapshot] ALWAYS use `insta`/`expect-test` for snapshot testing complex output

## Mocking

- [test-mockall] ALWAYS use `mockall` when verifying specific call args and fake is impractical
- [test-wiremock] ALWAYS use `wiremock` for HTTP mocking

## CLI & Fuzz Testing

- [test-assert-cmd] ALWAYS use `assert_cmd` + `predicates` for CLI e2e testing
- [test-cargo-fuzz] ALWAYS use `cargo-fuzz` for security-sensitive parsers
