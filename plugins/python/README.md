# Python Plugin

Code generation, evaluation, linting, and research for Python — with a decision-tree-based quality loop.

## Setup

Run `/setup-python-project` in your project to configure Ruff, Pyright, and pip-audit.

---

## Skills

### `/python-implement`

Implements Python code using a generator-evaluator loop: generates idiomatic code, evaluates against the decision tree, fixes violations, and repeats until clean (up to 3 cycles). Finishes with a full repo evaluation.

### `/python-generator`

Generates idiomatic Python 3.11+ code or provides architecture design guidance. Walks a decision tree across 8 problem categories (type design, protocols, error handling, concurrency, dependency management, resource management, project structure, testing) plus domain-specific categories (web API, database, CLI, data processing, ASGI, DDD).

### `/python-evaluator`

Evaluates Python code against 50+ rules across 9 categories. Reports only violations — no suggestions, no preamble.

### `/python-lint`

Runs the full linting suite: `ruff format`, `ruff check`, `pip-audit`, `pyright`, and `pytest`. Use before committing or as a CI check.

### `/python-researcher`

Researches the Python ecosystem via the web — packages, frameworks, cloud platforms, databases, ML/data tooling. Returns structured findings with links.

### `/setup-python-project`

Interactive setup for Ruff (linting/formatting), Pyright (type checking), and pip-audit (dependency scanning). Offers three strictness levels (chill, medium, strict) per tool.

---

## How guidelines work

Guidelines are organized as a numbered decision tree so the right rules load based on the problem at hand.

### Activity-scoped references

Loaded by `python-generator` when the task matches. Stored in `skills/python-generator/references/`:

| File                              | What it covers                                      |
|-----------------------------------|-----------------------------------------------------|
| `1-type-driven-design.md`         | NewType, Self type, Pydantic at boundaries          |
| `2-protocols.md`                  | Protocol vs ABC, structural typing                  |
| `3-data-modeling.md`              | dataclass, attrs, field validation                  |
| `4-error-handling.md`             | Exception hierarchies, raise from, ExceptionGroup   |
| `5-pattern-matching.md`           | match/case, Enum, dict dispatch                     |
| `6-context-managers.md`           | with statement, @contextmanager, ExitStack          |
| `7-descriptors-hooks.md`          | @property, descriptors, __init_subclass__           |
| `8-functional-patterns.md`        | Comprehensions, generators, itertools, caching      |
| `9-serialization.md`              | Pydantic BaseModel, msgspec, wire vs domain formats |
| `10-async-core.md`                | asyncio, event loops, async/await                   |
| `11-structured-concurrency.md`    | TaskGroup, cancellation, timeout, Semaphore         |
| `12-concurrency-models.md`        | ThreadPool, ProcessPool, free-threaded Python       |
| `13-dependency-injection.md`      | Constructor injection, FastAPI Depends               |
| `14-hexagonal-architecture.md`    | Ports & adapters, dependency direction              |
| `15-ddd.md`                       | Aggregates, value objects, domain events            |
| `16-functional-core.md`           | Pure functions, imperative shell                    |
| `17-project-organization.md`      | src/ layout, circular imports, uv workspaces        |
| `18-web-api.md`                   | FastAPI, Pydantic models, httpx testing             |
| `19-database.md`                  | SQLAlchemy 2.0, Mapped types, async sessions        |
| `20-cli.md`                       | Typer, Click, Rich output                           |
| `21-data-processing.md`           | Generator pipelines, itertools.batched, Polars      |
| `22-testing.md`                   | AAA pattern, pytest, fixtures, hypothesis, fakes    |
| `23-asgi.md`                      | Uvicorn, lifespan protocol, ASGI middleware         |
