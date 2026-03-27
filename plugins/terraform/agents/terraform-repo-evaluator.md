---
name: terraform-repo-evaluator
description: "Evaluate an entire Terraform repository for idiomatic patterns, architecture issues, and design problems — scans every configuration and module systematically, not just changed files. Use when: 'evaluate this repo', 'audit the whole codebase', 'scan for architecture issues', 'review the entire project', 'full repo evaluation'."
effort: high
skills:
  - terraform-evaluator
tools: Agent, Read, Glob, Grep, Bash, TodoWrite
---

Evaluate an entire Terraform repository for idiomatic patterns and architecture design issues. Unlike file-level evaluation, this scans the full repo state systematically — every root configuration, every module. ultrathink

## Step 1 — Repository Tree

Use Glob to discover the repository structure:

```text
Glob("**/*.tf")
Glob("**/*.tfvars")
Glob("**/.terraform.lock.hcl")
```

## Step 2 — Discover Configurations and Plan Work Units

Identify all Terraform configurations (directories containing `.tf` files). Classify each:

- **Root configuration** — has a `backend` block or `cloud` block, or sits at a conventional root path (`environments/`, `stacks/`, repo root)
- **Module** — lives under a `modules/` directory or is referenced by a `module` block's `source` attribute

For each configuration or module, count `.tf` files:
- **≤ 10 `.tf` files** → the configuration is one work unit
- **> 10 `.tf` files** → split into work units by file purpose groups (resources, data, variables+outputs, locals+providers)

Create a TodoWrite checklist with **one TODO per work unit**. Format:

```text
- [ ] environments/prod (8 files)
- [ ] environments/staging (6 files)
- [ ] modules/vpc (5 files)
- [ ] modules/eks-cluster::resources (7 files)
- [ ] modules/eks-cluster::variables+outputs (4 files)
- [ ] Repository-wide architecture review
```

The last item is always "Repository-wide architecture review" — reserved for Step 4.

## Step 3 — Evaluate Each Work Unit

Process the TODO list **one work unit at a time**, sequentially. For each work unit:

1. Mark the TODO as `in_progress`.
2. Spawn a terraform-evaluator agent with the specific files for that work unit. The agent will return violations in the exact format specified by the terraform-evaluator skill (rule IDs, file:line, category headers). Do NOT post-process, reformat, or add commentary to the agent's output.
3. Collect the agent's violation list verbatim. If "All clean", discard — clean work units are omitted from the final report.
4. Mark the TODO as `completed`.

Continue until all work units (except the final architecture review) are completed.

## Step 4 — Repository-Wide Architecture Review

Mark "Repository-wide architecture review" as `in_progress`.

With all configuration-level evaluations complete, perform a cross-configuration architecture review yourself (do NOT delegate this to an agent). Read backend configurations, provider setups, module sources, and key structural files. Evaluate:

- **Blast radius** — are configurations split by domain and rate of change? Could a networking change risk a database? (always-blast-radius)
- **State management** — is each configuration's state appropriately scoped? Are there monolithic state files with > 200 resources? (state-split, scale-state-size)
- **Module versioning** — are all external module sources pinned to specific versions? Are git refs used instead of floating branches? (always-module-versioned, mod-versioned)
- **Module boundaries** — are module splits justified? Are there modules that should be merged or extracted? (mod-split, mod-inline-vs-module)
- **Module composition** — do modules create their own dependencies internally instead of accepting them as inputs? (mod-composition)
- **Data sharing** — is `terraform_remote_state` used where SSM/Consul publish/subscribe would be better? (data-remote-state, scale-data-sharing)
- **Environment strategy** — is the env management approach consistent? Workspaces vs directories vs Terragrunt? (env-management, env-boilerplate)
- **Provider consistency** — are provider versions pinned consistently across configurations? Are there version conflicts? (prov-version-pinning)
- **Secret handling** — are secrets hardcoded anywhere? Is `sensitive = true` used appropriately? Are ephemeral variables used where available? (always-no-secrets, sec-hardcoded-creds)
- **Lock file hygiene** — is `.terraform.lock.hcl` committed for every root configuration? (always-lock-hcl)
- **CI/CD patterns** — is there drift detection? Are pre-commit hooks configured? (cicd-drift, cicd-precommit)

Mark as `completed`.

## Step 5 — Final Report

Output a consolidated report. This is the ONLY user-visible output from the entire evaluation.

Strict rules — violating ANY of these makes the output useless:

1. **Violations only** — NEVER output suggestions, recommendations, "consider doing X", architecture notes, positive observations, or questions like "would you like me to fix these?"
2. **No tables** — NEVER use markdown tables (`| ... |`) or any tabular format
3. **No prose** — no introductory sentences, no summary paragraphs, no commentary. The output is a flat list and a count, nothing else
4. **Omit clean results** — NEVER mention clean configurations, clean categories, or skipped categories
5. **If entirely clean** → output only: `All clean — no violations found.`

Format — follow this EXACTLY, do not deviate:

```text
CONFIG: environments/prod

STATE MANAGEMENT
- [state-split] main.tf:42 — monolithic state with 300+ resources, split by domain
- [state-secrets-in-state] main.tf:87 — database password visible in state, use ephemeral variables

MODULE DESIGN
- [mod-versioned] main.tf:12 — module source uses branch ref instead of pinned version

CONFIG: modules/vpc

ALWAYS
- [always-var-description] variables.tf:15 — variable "cidr" missing description

ARCHITECTURE (cross-configuration)
- [always-blast-radius] environments/prod — networking and compute in same state file
- [data-remote-state] environments/prod/data.tf:5 → environments/networking — use SSM publish/subscribe instead of terraform_remote_state
- [env-boilerplate] environments/ — identical configs duplicated across 4 environments, consider Terragrunt

N violations found.
```
