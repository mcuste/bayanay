---
name: python-generator
description: "Generate idiomatic Python code or design Python architecture. Use when: 'write Python code for', 'implement in Python', 'refactor to idiomatic Python', 'design this in Python', 'Python architecture for', 'what Python pattern should I use', 'how would you structure this in Python', 'how do I handle X in Python'."
argument-hint: "<feature, code to implement/refactor, or architecture to design>"
effort: high
allowed-tools: "Read, Glob, Grep"
---

Generate idiomatic Python code or a Python architecture design. ultrathink

## Mode

Determine mode from the request:

- **Code mode** — user wants working code ("implement", "write", "refactor", "add", "generate")
- **Design mode** — user wants architectural guidance ("design", "architect", "how would you structure", "what pattern", "plan")

## Process

### 1. Walk the Decision Tree

Work through every section of the decision tree below that applies to the problem. A single problem often matches multiple branches — identify all that apply and note which N references are relevant.

### 2. Read Relevant References (optional)

If a matched branch is unfamiliar or the right approach is unclear, read its linked reference file. Each file explains: **when** to use the pattern, **how** it works, and includes a code snippet.

### 3. Research (if needed)

If the decision tree and references are not enough — e.g., unfamiliar library API, unclear best practice, need to compare approaches, or need latest docs — research the specific question before generating output.

### 4. Generate Output

**Code mode:** Produce runnable, idiomatic Python 3.11+ code applying all identified patterns. Include `import` statements. Use type hints throughout. Prefer `Protocol` over `ABC`, `@dataclass(frozen=True, slots=True)` for domain objects, Pydantic `BaseModel` at boundaries. Preserve existing code style when refactoring.

**Design mode:** Output:

- Architecture issues found (if any) as a plain list — concrete problems with concrete fixes
- Module structure and package layout
- Key type signatures, Protocol definitions, and dataclass outlines (not full implementations)
- Dependency injection and layer boundaries
- Async/concurrency approach (if applicable)
- Trade-offs and rationale for each recommendation

---

## Always

These hold regardless of the specific problem:

- **Parse, don't validate** — validate at system boundaries (HTTP, config, CLI) using Pydantic; carry proof in the type internally with typed dataclasses; never scatter validation through the codebase
- **Explicit is better than implicit** — type hints everywhere, explicit `async`/`await`, explicit dependency injection via constructors, no magic globals
- **Protocol over ABC by default** — structural typing decouples code; use `ABC` only when shared implementation is needed
- **Start concrete, extract late** — write the concrete implementation first; extract a Protocol only when a second real implementation arrives
- **Dependencies flow one direction** — domain layer must never import from infrastructure; invert with Protocols defined in the domain layer
- **`frozen=True, slots=True` by default** — immutable dataclasses prevent accidental mutation, reduce memory, prevent typos; mutable only when justified
- **Test observable behavior, not implementation** — a test that breaks on a valid refactor has zero value; prefer output-based over interaction-based testing; fakes over mocks for stateful dependencies
- **Constructor injection is sufficient** — Python rarely needs DI frameworks; pass dependencies via `__init__`, wire in a composition root; FastAPI `Depends()` is the exception

---

## Decision Tree

### Is this a TYPE / MODELING problem?

- External input entering the system (HTTP, config, CLI)? → Pydantic v2 `BaseModel` at boundary, parse once [1](references/1-type-driven-design.md) [3](references/3-data-modeling.md) [9](references/9-serialization.md)
- Internal data object with no validation? → `@dataclass(frozen=True, slots=True)` [3](references/3-data-modeling.md)
- Internal data with field validation? → `attrs` with validators [3](references/3-data-modeling.md)
- High-throughput serialization bottleneck (measured)? → `msgspec.Struct` [9](references/9-serialization.md)
- Primitive represents a distinct domain concept (UserId vs OrderId)? → `NewType` (static) or newtype class (runtime enforcement) [1](references/1-type-driven-design.md)
- Need JSON Schema generation? → Pydantic v2 `model_json_schema()` [9](references/9-serialization.md)
- Wire format differs from domain type? → separate Pydantic models (API) + dataclasses (domain), convert at boundary [9](references/9-serialization.md) [14](references/14-hexagonal-architecture.md)
- Generic type parameter needed? → `type` syntax (3.12+) or `TypeVar` [1](references/1-type-driven-design.md)
- Method chaining returning self? → `Self` type (PEP 673, 3.11+) [1](references/1-type-driven-design.md)

---

### Is this an INTERFACE / ABSTRACTION problem?

- "I need something with `.read()` / `.write()` / `.close()`"? → `Protocol` — structural typing, no inheritance needed [2](references/2-protocols.md)
- Need shared default implementation across subtypes? → `ABC` with default methods [2](references/2-protocols.md)
- Plugin system — auto-register subclasses? → `__init_subclass__` + class registry dict [7](references/7-descriptors-hooks.md)
- Fixed set of variants (status codes, message types)? → `Enum` or union type [5](references/5-pattern-matching.md)
- Complex dispatch over data shape? → `match/case` [5](references/5-pattern-matching.md)
- Simple value dispatch (string → handler)? → dict lookup (faster, more Pythonic than match for this) [5](references/5-pattern-matching.md)
- Data transformation pipeline (filter, map, aggregate)? → comprehensions, generators, `itertools` [8](references/8-functional-patterns.md)
- Memoization for expensive pure function? → `@cache` / `@lru_cache` [8](references/8-functional-patterns.md)
- Reusable attribute validation across multiple classes? → descriptor [7](references/7-descriptors-hooks.md)
- One-off computed attribute? → `@property` [7](references/7-descriptors-hooks.md)
- Introducing a Protocol for a single existing implementation? → wait — extract only when a second real implementation arrives [2](references/2-protocols.md)
- Generic protocol for repository/service pattern? → `Protocol[T_co]` with covariant type parameter [2](references/2-protocols.md)
- Need `isinstance` checks on Protocol? → `@runtime_checkable` (checks method existence only, not signatures) [2](references/2-protocols.md)

---

### Is this an ERROR HANDLING problem?

- Need a module/package error hierarchy? → one base `AppError(Exception)`, specific subclasses carry structured data [4](references/4-error-handling.md)
- Multiple concurrent tasks failing? → `TaskGroup` + `except*` with `ExceptionGroup` (3.11+) [4](references/4-error-handling.md) [11](references/11-structured-concurrency.md)
- Adding operational context as error propagates? → `e.add_note()` (3.11+) — no wrapper exception needed [4](references/4-error-handling.md)
- Expected absence of a value? → return `None` with `T | None` type hint [1](references/1-type-driven-design.md)
- Should the caller distinguish failure modes?
  - Yes → raise typed exception (subclass of module base) [4](references/4-error-handling.md)
  - No → raise generic `AppError` or let it propagate
- Preserving the original cause? → `raise NewError(...) from original_error` — always [4](references/4-error-handling.md)
- Logging errors? → log when handled, not when propagated — avoid duplicate log entries [4](references/4-error-handling.md)

---

### Is this a CONCURRENCY problem?

- Many I/O operations (HTTP calls, DB queries, file reads)? → `asyncio` with `TaskGroup` (3.11+) [10](references/10-async-core.md) [11](references/11-structured-concurrency.md)
- Simple parallel I/O, few tasks? → `ThreadPoolExecutor` [12](references/12-concurrency-models.md)
- CPU-bound work, parallelizable? → `ProcessPoolExecutor` [12](references/12-concurrency-models.md)
- CPU + I/O mixed? → `asyncio` + `loop.run_in_executor(ProcessPoolExecutor, fn)` [12](references/12-concurrency-models.md)
- Blocking call inside async function? → `await loop.run_in_executor(None, blocking_fn)` [12](references/12-concurrency-models.md)
- True thread parallelism needed and measured? → Free-threaded Python 3.13t (experimental) [12](references/12-concurrency-models.md)
- Need to cancel all tasks on first failure? → `TaskGroup` — automatic cancellation [11](references/11-structured-concurrency.md)
- Need timeout on async operation? → `asyncio.timeout()` (3.11+) [11](references/11-structured-concurrency.md)
- Fan-out with bounded concurrency? → `TaskGroup` + `asyncio.Semaphore` [11](references/11-structured-concurrency.md)
- Shared mutable state across async tasks? → `asyncio.Lock`, or restructure to avoid shared state [10](references/10-async-core.md)

---

### Is this a DEPENDENCY / COUPLING problem?

- Infrastructure (DB, HTTP, filesystem) bleeding into domain logic? → hexagonal architecture — Protocols as ports, implementations as adapters [14](references/14-hexagonal-architecture.md)
- How to wire dependencies?
  - Simple (1-3 deps) → constructor injection, no framework [13](references/13-dependency-injection.md)
  - FastAPI → `Depends()` with Protocol-typed parameters [13](references/13-dependency-injection.md) [18](references/18-web-api.md)
  - Complex (many deps, deep graph) → `dependency-injector` or manual composition root [13](references/13-dependency-injection.md)
- Domain logic tangled with I/O / side effects? → functional core, imperative shell — pure functions for logic, side effects at edges [16](references/16-functional-core.md)
- Protocol logic tangled with network code? → sans-io pattern — protocol state machine as pure class, I/O adapter wraps it
- Need to enforce layer boundaries (domain must not import infra)? → `import-linter` with layered contract [17](references/17-project-organization.md)
- Circular imports between modules? → extract shared types to a common module; use `TYPE_CHECKING` for type-only imports [17](references/17-project-organization.md)

---

### Is this a RESOURCE MANAGEMENT problem?

- Resource must be released even on exception (file, connection, lock)? → context manager (`with` statement) [6](references/6-context-managers.md)
- Async resource (async client, DB session)? → `async with` + `@asynccontextmanager` [6](references/6-context-managers.md)
- Dynamic / variable number of resources? → `ExitStack` or `AsyncExitStack` [6](references/6-context-managers.md)
- Application-scoped resources (connection pool, cache client)? → lifespan context manager in FastAPI/Starlette [18](references/18-web-api.md) [23](references/23-asgi.md)
- Startup/shutdown lifecycle in ASGI? → lifespan protocol [23](references/23-asgi.md)

---

### Is this a PROJECT STRUCTURE problem?

- Script or single-module tool? → flat module, no architecture needed — functions + a few dataclasses [17](references/17-project-organization.md)
- Package layout? → `src/` layout with `pyproject.toml` (PEP 621) [17](references/17-project-organization.md)
- 1-2 developers, short-lived project? → service layer + repository pattern with Protocols [13](references/13-dependency-injection.md) [14](references/14-hexagonal-architecture.md)
- Team project, long-lived? → hexagonal architecture [14](references/14-hexagonal-architecture.md)
  - `domain/` (dataclasses, pure logic, Protocols for ports)
  - `adapters/` (implementations: DB, HTTP, filesystem)
  - `application/` (use cases, orchestration)
  - `entrypoints/` (FastAPI app, CLI, workers)
- Monorepo with shared code? → workspace packages (uv workspaces, hatch) [17](references/17-project-organization.md)
- Module has grown too large? → split by domain boundary, not technical layer; flat over nested [17](references/17-project-organization.md)
- Package management? → uv (Rust-based, 10-100x faster than pip) [17](references/17-project-organization.md)

---

### Is this a TESTING problem?

- What kind of code is this? [22](references/22-testing.md)
  - Pure domain logic, few deps → unit test heavily
  - Trivial (getters, simple delegation) → don't test
  - Controller/handler with many deps → integration test
  - Complex with many deps → refactor first (split domain + orchestration)
- Writing a unit test? [22](references/22-testing.md)
  - Follow AAA (Arrange / Act / Assert)
  - Prefer output-based → state-based → interaction-based
  - Use pytest fixtures for setup, parametrize for variants
  - No mocks for domain logic — use real collaborators
- Testing with external services (DB, queues, APIs)? → testcontainers for Docker-based fixtures [22](references/22-testing.md)
- Testing FastAPI endpoints? → `httpx.AsyncClient` + app lifespan [18](references/18-web-api.md) [22](references/22-testing.md)
- Testing complex structured output? → snapshot tests: syrupy or inline-snapshot [22](references/22-testing.md)
- Testing invariants over arbitrary input? → property-based: hypothesis with strategies [22](references/22-testing.md)
- Need a test double for a stateful dependency? → hand-written fake (e.g. `InMemoryRepo`) — more reliable than mocks [22](references/22-testing.md)
- Async test? → `pytest-asyncio` with `asyncio_mode = "auto"` [22](references/22-testing.md)

---

### What DOMAIN is this for?

- Web API → FastAPI + Pydantic models + `Depends` DI + lifespan [18](references/18-web-api.md)
- Database access → SQLAlchemy 2.0 + `Mapped` types + async sessions [19](references/19-database.md)
- CLI tool → Typer (type hints) or Click (decorators) + Rich output [20](references/20-cli.md)
- Data processing → generator pipelines + `itertools.batched` + Polars [8](references/8-functional-patterns.md) [21](references/21-data-processing.md)
- ASGI server → Uvicorn + lifespan protocol + middleware stack [23](references/23-asgi.md)
- DDD / complex domain → aggregates, value objects, domain events, unit of work [15](references/15-ddd.md)
