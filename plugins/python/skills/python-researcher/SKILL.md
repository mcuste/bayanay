---
name: python-researcher
description: "Research Python ecosystem, packages, frameworks, cloud platforms, databases, infrastructure, and developer tooling — fetches latest official docs and returns structured findings. Use when: 'research this package', 'look up Python docs for', 'what's the latest on', 'find Python examples of', 'compare these Python packages', 'how does X work in Python'."
argument-hint: "<topic, package, framework, tool, or question to research>"
effort: high
allowed-tools: "WebSearch, WebFetch, Read"
---

Research Python ecosystem, cloud platforms, databases, infrastructure tools, and developer tooling from authoritative sources. ultrathink

## Process

1. **Understand the query** — Determine what needs researching: package API, framework feature, cloud platform integration, database configuration, infrastructure tooling, best practice, convention, migration guide, comparison, etc.

2. **Search and fetch** — Use WebSearch to find relevant sources, then WebFetch to read the actual content. Read the relevant reference URL file(s) for authoritative sources to check first. Always fetch multiple sources to cross-reference.

   **Reference URLs** — read only the file(s) matching the query topic:
   - Python language, PEPs, type system, async, packages: [urls-python-ecosystem.md](references/urls-python-ecosystem.md)
   - AWS, GCP, Azure, Docker, Kubernetes, CI/CD: [urls-cloud-infra.md](references/urls-cloud-infra.md)
   - PostgreSQL, Redis, Kafka, SQLAlchemy, messaging: [urls-databases-messaging.md](references/urls-databases-messaging.md)
   - OpenTelemetry, structlog, Prometheus, Sentry: [urls-observability.md](references/urls-observability.md)
   - Polars, Pandas, NumPy, ML/AI, data processing: [urls-data-ml.md](references/urls-data-ml.md)

   - **Always fetch latest version docs** unless a specific version is requested. Use `/latest/` or `/stable/` in doc URLs, not pinned versions. If the user's `pyproject.toml` pins an older version, still research latest — but note any breaking changes or migration steps between their version and latest.

   **Local package sources** — when you need the exact API of a pinned dependency version, or web docs are insufficient:
   - Read `pyproject.toml` / `uv.lock` / `requirements.txt` first to find the exact version in use
   - Installed package source lives at `.venv/lib/python3.*/site-packages/{package_name}/`
   - Start with `__init__.py` for the public API surface — look for `__all__`, public classes, functions, and re-exports
   - Check `py.typed` marker for typing support and `_types.py` or stub files for type information
   - Read `README.md` or module-level docstrings for guides the package author wrote
   - For workspace-local packages, read source directly from the workspace

3. **Output** — Return structured findings:

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
   - Include code examples when relevant — use Python code blocks
   - Note version-specific information (e.g., "as of Pydantic 2.6", "requires Python 3.12+")
   - Flag conflicting advice between sources
   - NEVER use markdown tables (`| ... |`) anywhere in output
