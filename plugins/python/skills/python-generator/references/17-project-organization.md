# §17 — Project Organization

## When to Use

- Setting up a new Python package or project
- Choosing package layout (`src/` vs flat)
- Configuring `pyproject.toml` (PEP 621)
- Choosing package manager (uv recommended)
- Organizing modules for a growing codebase

## How It Works

**`src/` layout:** Prevents accidentally importing source instead of installed package. Industry standard (recommended by pytest, setuptools, Hynek Schlawack).

**`pyproject.toml`:** Single source of truth for metadata, dependencies, and tool configuration. Replaces `setup.py`, `setup.cfg`, `requirements.txt`.

**uv:** Rust-based package manager (10-100x faster than pip). Built-in venv management, lock files, replaces pip + pip-tools + virtualenv + poetry.

## Code Snippet

```
myproject/
├── pyproject.toml
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── domain/
│       │   ├── __init__.py
│       │   ├── models.py
│       │   └── services.py
│       ├── adapters/
│       │   ├── __init__.py
│       │   ├── postgres.py
│       │   └── api/
│       │       ├── __init__.py
│       │       └── routes.py
│       └── config.py
├── tests/
│   ├── unit/
│   │   └── test_services.py
│   ├── integration/
│   │   └── test_postgres.py
│   └── conftest.py
└── uv.lock
```

```toml
# pyproject.toml
[project]
name = "myproject"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110",
    "sqlalchemy[asyncio]>=2.0",
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.23",
    "mypy>=1.8",
    "ruff>=0.3",
]

[tool.ruff]
target-version = "py311"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "RUF"]

[tool.mypy]
strict = true
plugins = ["pydantic.mypy"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

```bash
# uv commands
uv init myproject && cd myproject
uv add fastapi sqlalchemy pydantic
uv add --dev pytest ruff mypy
uv run python -m pytest
uv run mypy src/
uv lock && uv sync
```

## Notes

- `src/` layout forces `pip install -e .` — tests run against the installed version
- `pyproject.toml` is the modern standard — avoid `setup.py`, `setup.cfg`, `requirements.txt`
- uv is 10-100x faster than pip — from the makers of ruff
- Split by domain boundary, not technical layer — flat over deeply nested modules
- Use `import-linter` to enforce layer boundaries (domain must not import from adapters)
- Circular imports → extract shared types to a common module; use `TYPE_CHECKING` for type-only imports
