---
name: setup-python-project
description: "Set up a Python project — Ruff linting/formatting, Pyright type checking, and pip-audit based on project type and workflow. Use when: 'set up Python project', 'configure ruff', 'configure Python linting', 'Python project setup'."
argument-hint: "<project or workspace path>"
---

# Setup Python Project

You are setting up a Python project's tooling. Use `AskUserQuestion` to gather information step by step. Generate configuration by reading and adapting the preset files in `references/` (relative to this skill file).

## Reference Files

| File                  | Purpose                                         |
|-----------------------|-------------------------------------------------|
| `ruff-chill.toml`     | Ruff: minimal, catch real errors only           |
| `ruff-medium.toml`    | Ruff: broad coverage with noisy rules silenced  |
| `ruff-strict.toml`    | Ruff: ALL rules, known-noisy suppressed         |
| `pyright-chill.toml`  | Pyright: basic mode, no annotation enforcement  |
| `pyright-medium.toml` | Pyright: standard mode with extra diagnostics   |
| `pyright-strict.toml` | Pyright: strict mode, cascade-prone rules tamed |

## Step 1: Project Info

Call `AskUserQuestion` with 5 questions:

**Question 1** — "What type of project is this?", header: "Project type", multiSelect: true

- "Application / CLI tool" — user-facing executable; print() and assert are intentional
- "Library package" — consumed as a dependency; needs stricter docs and types
- "API server / web service" — structured logging, async considerations
- "Data / ML pipeline" — pandas, numpy; relaxed naming and magic values

**Question 2** — "What Python version are you targeting?", header: "Python version", multiSelect: false

- "3.10"
- "3.11"
- "3.12"
- "3.13"

**Question 3** — "Any frameworks in use?", header: "Frameworks", multiSelect: true

- "Django"
- "FastAPI"
- "Flask"
- "None"

**Question 4** — "Will this be published to PyPI?", header: "Publishing", multiSelect: false

- "Yes"
- "No"

**Question 5** — "Which tools do you want to set up?", header: "Tools", multiSelect: true

- "Ruff — lint + format configuration in pyproject.toml (Recommended)"
- "Pyright — type checking configuration in pyproject.toml (Recommended)"
- "pip-audit — dependency vulnerability scanning (no config file, CLI only)"

Skip configuration for any tool the user deselects. The comparison table and adjustments in later steps still reference all tools — only show rows/options relevant to the selected tools.

Wait for answers before proceeding.

## Step 2: Strictness Level

Present the comparison tables for each selected tool, then ask for a strictness level per tool in a single `AskUserQuestion` call. Only show questions for tools the user selected in Step 1.

### Ruff comparison

|                       | Chill                     | Medium                       | Strict                         |
|-----------------------|---------------------------|------------------------------|--------------------------------|
| **Rule selection**    | 7 groups (errors+hygiene) | 18 groups (security+quality) | ALL (noisy suppressed)         |
| **Security (S)**      | —                         | Enabled                      | Enabled                        |
| **Naming (N)**        | —                         | Enabled                      | Enabled                        |
| **Docstrings (D)**    | —                         | —                            | Enabled (conflicts resolved)   |
| **Annotations (ANN)** | —                         | —                            | Enabled (tests exempted)       |
| **Formatter compat**  | Yes                       | Yes                          | Yes (conflicts suppressed)     |
| **Best for**          | Prototypes, scripts       | Most projects                | Libraries, safety-critical, AI |

### Pyright comparison

|                         | Chill        | Medium        | Strict                       |
|-------------------------|--------------|---------------|------------------------------|
| **Mode**                | basic        | standard      | strict                       |
| **Type annotations**    | Not required | Not required  | Required on all parameters   |
| **Unknown types**       | Ignored      | Ignored       | Warned (cascade-prone tamed) |
| **Missing stubs**       | Ignored      | Warning       | Warning                      |
| **Unused imports/vars** | Ignored      | Warning       | Error                        |
| **Best for**            | Prototypes   | Most projects | Libraries, safety-critical   |

pip-audit has no strictness levels — it scans for known vulnerabilities and either finds them or doesn't.

Call `AskUserQuestion` with one question per selected tool (skip pip-audit):

**Question 1** (if Ruff selected) — "Ruff strictness level?", header: "Ruff", multiSelect: false

- "Chill — catch real errors, stay out of the way"
- "Medium — broad coverage with security checks (Recommended)"
- "Strict — maximum coverage, every rule not explicitly silenced is active"

**Question 2** (if Pyright selected) — "Pyright strictness level?", header: "Pyright", multiSelect: false

- "Chill — basic type checking, no annotation enforcement"
- "Medium — standard mode with extra diagnostics (Recommended)"
- "Strict — full coverage, cascade-prone rules tamed"

Wait for answers before proceeding.

## Step 3: Project-Specific Adjustments

Based on the project type from Step 1, present **only the relevant** adjustments below. Combine all applicable adjustments into a single `AskUserQuestion` with multiSelect: true. Pre-select recommended options with "(Recommended)" suffix.

### If Application / CLI tool

- "Allow print() — stdout/stderr are intentional for CLIs (Recommended)" — remove `T20` from ruff select (chill/medium) or add `T201`, `T203` to ignore (strict)
- "Allow assert — intentional for scripts (Recommended)" — add `S101` to ruff ignore

### If Library package

- "Enable docstring rules (Recommended)" — add `D` to ruff select with `[tool.ruff.lint.pydocstyle] convention = "google"` and ignore `D203`, `D213` (medium preset only; strict already has this)
- "Warn on missing type annotations (Recommended)" — if pyright is not already strict, add `reportMissingParameterType = "warning"` and `reportMissingReturnType = "warning"`

### If API server / web service

- "Add async rules (Recommended)" — add `ASYNC` to ruff select (if not already in preset)
- "Enable FastAPI rules" (if FastAPI selected) — add `FAST` to ruff select

### If Data / ML pipeline

- "Add pandas rules (Recommended)" — add `PD` to ruff select
- "Add numpy rules (Recommended)" — add `NPY` to ruff select
- "Relax magic value checks — common in data code (Recommended)" — add `PLR2004` to ruff ignore

### If Django

- "Add Django rules (Recommended)" — add `DJ` to ruff select

### If Publishing to PyPI

- "Enforce docstring conventions (Recommended)" — add `D` to ruff select if not already present

### General adjustments (always ask in a second call)

Call `AskUserQuestion` with these questions:

**Question 1** — "Docstring convention?", header: "Docstrings", multiSelect: false (skip if D rules are not enabled)

- "Google style (Recommended)"
- "NumPy style"
- "PEP 257"

**Question 2** — "Source layout?", header: "Layout", multiSelect: false

- "src layout (`src/package/`)" — set `[tool.ruff] src = ["src"]` and pyright `include = ["src"]`
- "Flat layout (`package/` at root)" — no extra config needed
- "Single module (`module.py` at root)" — no extra config needed

## Step 4: Generate & Apply

### Build the configuration

1. Read the reference preset files for the chosen level:
   - `references/ruff-{level}.toml` — base ruff config
   - `references/pyright-{level}.toml` — base pyright config

2. Apply all adjustments from Step 3 to the preset content.

3. Update `target-version` (ruff) and `pythonVersion` (pyright) to match the Python version from Step 1.

4. Merge both tool configs into a single `pyproject.toml` `[tool.*]` section set.

### Review

Show the user the generated config in a single response:

1. **Ruff config** — the `[tool.ruff]`, `[tool.ruff.lint]`, `[tool.ruff.format]`, and any sub-tables
2. **Pyright config** — the `[tool.pyright]` section
3. **pip-audit** — the recommended CLI invocation (no config file)

Call `AskUserQuestion`:

**Question** — "What would you like to do?", header: "Apply", multiSelect: false

- "Apply all — write configs to pyproject.toml"
- "Make adjustments first" — ask what to change, regenerate, re-prompt
- "Just show me — I'll apply myself"

### If "Apply all"

1. Update `pyproject.toml` with ruff and pyright sections (preserve existing content)
2. Run `ruff check .` to show current violations
3. Run `ruff format --check .` to show formatting status
4. Call `AskUserQuestion` — "Ruff found violations. What would you like to do?", header: "Violations", multiSelect: false
   - "Fix auto-fixable issues now" — run `ruff check --fix .` and `ruff format .`
   - "Address them manually" — continue to Step 5
   - "Leave as warnings for now" — continue to Step 5

## Step 5: Formatter Settings

Check if `[tool.ruff.format]` exists in `pyproject.toml`. If missing, suggest:

```toml
[tool.ruff.format]
quote-style = "double"
indent-style = "space"
docstring-code-format = true
```

Call `AskUserQuestion` — "Formatter preferences?", header: "Formatting", multiSelect: false

- "Defaults (double quotes, spaces) — matches Black (Recommended)"
- "Single quotes" — set `quote-style = "single"`
- "Skip — I'll configure formatting myself"
