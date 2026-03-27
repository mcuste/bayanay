# Terraform Plugin

Code generation, evaluation, linting, and research for Terraform — with a decision-tree-based quality loop.

## Setup

Run `/setup-terraform-project` in your project to configure TFLint and Checkov.

---

## Skills

### `/terraform-generator`

Generates idiomatic Terraform HCL or provides architecture design guidance. Walks a decision tree across 14 infrastructure design categories and auto-lints generated code (up to 3 iterations).

### `/terraform-evaluator`

Evaluates Terraform code against 74 rules across 12 architectural categories. Reports only violations — no suggestions, no preamble.

### `/terraform-lint`

Runs the full linting suite: `terraform fmt`, `terraform validate`, `tflint`, `trivy`, and `checkov`. Use before committing or as a CI check.

### `/terraform-researcher`

Researches the Terraform ecosystem via the web — providers, modules, CI/CD tools, security patterns, scaling strategies. Returns structured findings with links.

### `/setup-terraform-project`

Interactive setup for TFLint and Checkov. Offers three strictness levels (chill, medium, strict) per tool, with provider-specific plugin configuration for AWS, Azure, and GCP.

---

## How guidelines work

Guidelines are organized as a numbered decision tree so the right rules load based on the infrastructure concern.

### Activity-scoped references

Loaded by `terraform-generator` when the task matches. Stored in `skills/terraform-generator/references/`:

| File                           | What it covers                                        |
|--------------------------------|-------------------------------------------------------|
| `1-state-management.md`        | Remote backends, locking, state key design            |
| `2-module-design.md`           | Module structure, composition, versioning             |
| `3-code-organization.md`       | Directory structure, monorepo vs polyrepo             |
| `4-environment-management.md`  | Dev/staging/prod, workspaces, Terragrunt              |
| `5-variables-configuration.md` | Validation, optional(), dynamic blocks, for_each      |
| `6-provider-management.md`     | Multi-region, multi-account, provider aliases         |
| `7-data-flow.md`               | depends_on, data sources, remote_state, moved blocks  |
| `8-testing-validation.md`      | terraform test, Checkov, OPA/Rego, Terratest          |
| `9-cicd-patterns.md`           | PR workflows, OIDC, drift detection, Infracost       |
| `10-security-patterns.md`      | OIDC federation, Vault, IAM least privilege           |
| `11-scaling-patterns.md`       | Microstack architecture, state splitting, Terragrunt  |
| `12-resource-lifecycle.md`     | create_before_destroy, prevent_destroy, ignore_changes|
| `13-import-migration.md`       | Import blocks, bulk import, moved/removed blocks      |
| `14-performance.md`            | State splitting, parallelism, large for_each          |
