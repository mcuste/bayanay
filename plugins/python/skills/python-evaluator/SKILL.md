---
name: python-evaluator
description: "Evaluate Python code for idiomatic patterns and architecture. Use when: 'review Python code', 'check if this Python is idiomatic', 'evaluate Python patterns', 'audit Python architecture', 'does this Python code follow best practices', 'review these Python files'."
argument-hint: "<file path(s), code, or git diff>"
effort: high
allowed-tools: "Read, Glob, Grep, TodoWrite"
---

Evaluate Python code against the decision tree from the python-generator skill. ultrathink

## Process

1. **Read the Code** — Read all files provided. If given a directory or glob, discover `.py` files and `pyproject.toml`.

2. **Select Categories & Create Checklist** — Determine which of the 9 decision tree categories apply (Always rules always apply). Create a TodoWrite checklist with **one TODO per applicable category**, listing all rule IDs in that category. Do NOT output anything to the user during this step — category selection is internal. Example:

   ```text
   - [ ] Always: always-parse-validate, always-explicit, always-protocol-default, ...
   - [ ] Type/Modeling: type-boundary-pydantic, type-internal-dataclass, ...
   - [ ] Concurrency: conc-gather-over-taskgroup, conc-blocking-async, ...
   ```

3. **Check Rules** — Work through the TODO list **one category at a time**. The entire checking process is internal — do NOT output ANY text to the user during this step (no summaries, no "all clean" per category, no skip reasons, no reasoning). For each category:
   1. Mark the category as `in_progress`.
   2. Evaluate **every rule by ID** in that category against every file. For each rule, decide: violation or clean.
   3. Mark the category as `completed`.

   Rules for checking:
   - **When in doubt, skip it.** Only flag a rule when the violation is unambiguous — any competent Python reviewer would agree it applies. A missed violation is acceptable. If you find yourself weighing pros and cons of whether a rule applies, it is not clear enough to flag.
   - **Be exhaustive.** When a rule is violated in multiple locations, list **every** occurrence with its line number — do not summarize as "throughout the file" or pick representative examples.
   - If a matched rule is unfamiliar or the right approach is unclear, read its linked reference file from the python-generator skill at `${CLAUDE_SKILL_DIR}/../python-generator/references/`.

4. **Output** — This is the ONLY step that produces user-visible output. List all violations grouped by category. If all clean, output `All clean — no violations found.`

   - Only report violations, NEVER suggestions — if a rule does not clearly apply, skip it
   - NEVER explain skipped categories or clean categories — omit them entirely
   - NEVER use markdown tables (`| ... |`) anywhere in output

   Format:

   ```text
   CORRECTNESS
   - [type-boundary-pydantic] file:line — description
   - [err-raise-from] file:line — description

   CONCURRENCY
   - [conc-blocking-async] file:line — description

   N violations found.
   ```

---

## Always

These hold regardless of the specific problem — flag any violation.

- `always-parse-validate` **Parse, don't validate** — validate at system boundaries (HTTP, config, CLI) using Pydantic; carry proof in the type internally with typed dataclasses; never scatter validation through the codebase [1](../python-generator/references/1-type-driven-design.md) [3](../python-generator/references/3-data-modeling.md)
- `always-explicit` **Explicit is better than implicit** — type hints everywhere, explicit `async`/`await`, explicit dependency injection via constructors, no magic globals
- `always-protocol-default` **Protocol over ABC by default** — structural typing decouples code; use `ABC` only when shared implementation is needed [2](../python-generator/references/2-protocols.md)
- `always-concrete-first` **Start concrete, extract late** — write the concrete implementation first; extract a Protocol only when a second real implementation arrives [2](../python-generator/references/2-protocols.md)
- `always-dep-direction` **Dependencies flow one direction** — domain layer must never import from infrastructure; invert with Protocols defined in the domain layer [14](../python-generator/references/14-hexagonal-architecture.md)
- `always-frozen-slots` **`frozen=True, slots=True` by default** — immutable dataclasses prevent accidental mutation, reduce memory, prevent typos; mutable only when justified [3](../python-generator/references/3-data-modeling.md)
- `always-test-behavior` **Test observable behavior, not implementation** — a test that breaks on a valid refactor has zero value; prefer output-based over interaction-based testing; fakes over mocks for stateful dependencies [22](../python-generator/references/22-testing.md)
- `always-constructor-di` **Constructor injection is sufficient** — Python rarely needs DI frameworks; pass dependencies via `__init__`, wire in a composition root; FastAPI `Depends()` is the exception [13](../python-generator/references/13-dependency-injection.md)

---

## Decision Tree

### Is this a TYPE / MODELING problem?

- `type-boundary-pydantic` External / unvalidated input entering the system (HTTP, config, CLI)? → Pydantic v2 `BaseModel` at boundary, parse once [1](../python-generator/references/1-type-driven-design.md) [3](../python-generator/references/3-data-modeling.md) [9](../python-generator/references/9-serialization.md)
- `type-internal-dataclass` Internal data object with no validation? → `@dataclass(frozen=True, slots=True)` [3](../python-generator/references/3-data-modeling.md)
- `type-internal-attrs` Internal data with field validation? → `attrs` with validators [3](../python-generator/references/3-data-modeling.md)
- `type-newtype-confusion` Primitive represents a distinct domain concept (UserId vs OrderId)? → `NewType` (static) or newtype class (runtime enforcement) [1](../python-generator/references/1-type-driven-design.md)
- `type-wire-domain` Wire / serialization format differs from domain type? → separate Pydantic models (API) + dataclasses (domain), convert at boundary [9](../python-generator/references/9-serialization.md) [14](../python-generator/references/14-hexagonal-architecture.md)
- `type-missing-slots` Dataclass without `slots=True` (3.10+)? → add `slots=True` — reduces memory, prevents accidental attribute assignment [3](../python-generator/references/3-data-modeling.md)
- `type-mutable-default` Mutable default argument in dataclass or function (`list`, `dict`, `set`)? → use `field(default_factory=list)` for dataclasses, or `None` sentinel for functions [3](../python-generator/references/3-data-modeling.md)
- `type-missing-hints` Public function or method missing type hints? → add type hints — they're architecture, not decoration [1](../python-generator/references/1-type-driven-design.md)
- `type-pydantic-internal` Pydantic `BaseModel` used for internal domain objects (not at a boundary)? → `@dataclass(frozen=True, slots=True)` — don't couple domain to a serialization library [3](../python-generator/references/3-data-modeling.md)

---

### Is this an INTERFACE / ABSTRACTION problem?

- `iface-abc-over-protocol` Using `ABC` where `Protocol` suffices (no shared implementation needed)? → `Protocol` — structural typing, no inheritance required [2](../python-generator/references/2-protocols.md)
- `iface-premature-protocol` Introducing a Protocol for a single existing implementation? → wait — extract only when a second real implementation arrives [2](../python-generator/references/2-protocols.md)
- `iface-dispatch-dict` Using `match/case` or `if/elif` chain for simple value-to-handler dispatch? → dict lookup is faster and more Pythonic [5](../python-generator/references/5-pattern-matching.md)
- `iface-dispatch-match` Nested `if/elif` chain inspecting type, shape, and value of data? → `match/case` (3.10+) [5](../python-generator/references/5-pattern-matching.md)
- `iface-metaclass` Using metaclass where `__init_subclass__` suffices (plugin registration, subclass validation)? → `__init_subclass__` is simpler and sufficient for most cases [7](../python-generator/references/7-descriptors-hooks.md)
- `iface-runtime-checkable` Relying on `@runtime_checkable` Protocol for validation? → only checks method *existence*, not signatures — don't use for runtime type validation [2](../python-generator/references/2-protocols.md)
- `iface-property-scale` Using `@property` for reusable validation across multiple classes? → descriptor is reusable; `@property` is for one-off computed attributes [7](../python-generator/references/7-descriptors-hooks.md)

---

### Is this an ERROR HANDLING problem?

- `err-bare-except` Bare `except:` or overly broad `except Exception:`? → catch specific exception types [4](../python-generator/references/4-error-handling.md)
- `err-swallowed` Exception caught and silently ignored (empty `except` body, or `pass`)? → handle meaningfully or propagate [4](../python-generator/references/4-error-handling.md)
- `err-raise-from` Raising a new exception without `from` (losing the original cause)? → `raise NewError(...) from original_error` — always preserve the cause chain [4](../python-generator/references/4-error-handling.md)
- `err-hierarchy` Package/module with multiple custom exceptions but no common base? → one base `AppError(Exception)`, specific subclasses [4](../python-generator/references/4-error-handling.md)
- `err-string-only` Exception carries only a message string, callers need structured data? → carry structured fields on the exception class [4](../python-generator/references/4-error-handling.md)
- `err-log-propagate` Logging an error AND re-raising it (causes duplicate log entries up the stack)? → log at the handler, not during propagation [4](../python-generator/references/4-error-handling.md)
- `err-exception-group` Multiple concurrent task failures handled with single exception (losing errors)? → `TaskGroup` + `except*` with `ExceptionGroup` (3.11+) [4](../python-generator/references/4-error-handling.md) [11](../python-generator/references/11-structured-concurrency.md)

---

### Is this a CONCURRENCY problem?

- `conc-gather-over-taskgroup` Using `asyncio.gather()` where `TaskGroup` should be used (3.11+)? → `TaskGroup` — automatic cancellation on failure, proper error aggregation [11](../python-generator/references/11-structured-concurrency.md)
- `conc-fire-forget` `asyncio.create_task()` without tracking (fire-and-forget)? → `TaskGroup` for structured lifetime; untracked tasks swallow exceptions [11](../python-generator/references/11-structured-concurrency.md)
- `conc-blocking-async` Blocking call inside an async function (file I/O, CPU work, `time.sleep`)? → `await loop.run_in_executor(None, blocking_fn)` [10](../python-generator/references/10-async-core.md) [12](../python-generator/references/12-concurrency-models.md)
- `conc-unbounded-fanout` Unbounded number of concurrent tasks (no limit on parallelism)? → `TaskGroup` + `asyncio.Semaphore` [11](../python-generator/references/11-structured-concurrency.md)
- `conc-cpu-in-async` CPU-bound work running directly in async event loop? → `ProcessPoolExecutor` + `loop.run_in_executor` [12](../python-generator/references/12-concurrency-models.md)
- `conc-no-timeout` Long-running async operation without timeout? → `asyncio.timeout()` (3.11+) [11](../python-generator/references/11-structured-concurrency.md)
- `conc-shared-state` Shared mutable state across async tasks without synchronization? → `asyncio.Lock`, or restructure to avoid shared state [10](../python-generator/references/10-async-core.md)

---

### Is this a DEPENDENCY / COUPLING problem?

- `coup-infra-in-domain` Infrastructure (DB, HTTP, filesystem, serialization) imported in domain layer? → hexagonal architecture — Protocols as ports, implementations as adapters [14](../python-generator/references/14-hexagonal-architecture.md)
- `coup-io-in-logic` Domain logic tangled with I/O / side effects? → functional core, imperative shell — pure functions for logic, side effects at edges [16](../python-generator/references/16-functional-core.md)
- `coup-circular-import` Circular imports between modules? → extract shared types to a common module; use `TYPE_CHECKING` for type-only imports [17](../python-generator/references/17-project-organization.md)
- `coup-di-framework` Using a DI framework for simple dependency wiring (1–3 deps)? → constructor injection is sufficient, no framework needed [13](../python-generator/references/13-dependency-injection.md)
- `coup-service-locator` Global registry / service locator pattern that hides dependencies? → explicit constructor injection — make dependencies visible in the `__init__` signature [13](../python-generator/references/13-dependency-injection.md)

---

### Is this a RESOURCE MANAGEMENT problem?

- `res-no-context-manager` Resource (file, connection, lock, transaction) acquired without context manager? → `with` statement ensures cleanup even on exception [6](../python-generator/references/6-context-managers.md)
- `res-manual-cleanup` Manual `try/finally` for resource cleanup? → `@contextmanager` or class-based context manager [6](../python-generator/references/6-context-managers.md)
- `res-async-resource` Async resource not using `async with`? → `async with` + `@asynccontextmanager` [6](../python-generator/references/6-context-managers.md)
- `res-dynamic-resources` Variable number of resources opened individually? → `ExitStack` / `AsyncExitStack` [6](../python-generator/references/6-context-managers.md)
- `res-missing-lifespan` Application-scoped resources (connection pool, cache) not managed by lifespan? → lifespan context manager in FastAPI/Starlette [18](../python-generator/references/18-web-api.md) [23](../python-generator/references/23-asgi.md)

---

### Is this a PROJECT STRUCTURE problem?

- `mod-no-src-layout` Package without `src/` layout? → `src/` layout prevents accidental source imports during tests [17](../python-generator/references/17-project-organization.md)
- `mod-mixed-concerns` Module mixing domain logic with I/O or unrelated concerns? → split by domain boundary, not technical layer [17](../python-generator/references/17-project-organization.md)
- `mod-circular-deps` Circular module dependencies? → extract shared types to a common module [17](../python-generator/references/17-project-organization.md)
- `mod-over-nested` Deeply nested package structure with unnecessary `__init__.py` layers? → flat over nested [17](../python-generator/references/17-project-organization.md)
- `mod-star-import` Wildcard `from module import *`? → explicit imports; define `__all__` if the module is a public API surface [17](../python-generator/references/17-project-organization.md)

---

### Is this a TESTING problem?

- `test-mock-domain` Mocking pure domain logic or value objects? → use real collaborators — domain logic should be testable without mocks [22](../python-generator/references/22-testing.md)
- `test-mock-over-fake` `unittest.mock` for stateful dependency (repo, external service)? → hand-written fake (e.g. `InMemoryRepo`) — catches interface drift, more reliable [22](../python-generator/references/22-testing.md)
- `test-implementation` Testing implementation details (private methods, internal state, call counts)? → test observable behavior — inputs and outputs [22](../python-generator/references/22-testing.md)
- `test-missing-parametrize` Repeated test code for multiple input variants? → `pytest.mark.parametrize` [22](../python-generator/references/22-testing.md)
- `test-sync-async` Sync test for async code (e.g. `asyncio.run()` in test)? → `pytest-asyncio` with `asyncio_mode = "auto"` [22](../python-generator/references/22-testing.md)
- `test-no-aaa` Test without clear Arrange / Act / Assert structure? → follow AAA pattern [22](../python-generator/references/22-testing.md)
