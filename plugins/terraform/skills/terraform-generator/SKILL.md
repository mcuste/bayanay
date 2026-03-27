---
name: terraform-generator
description: "Generate idiomatic Terraform code or design Terraform architecture. Use when: 'write Terraform code for', 'implement in Terraform', 'refactor Terraform config', 'design this in Terraform', 'Terraform architecture for', 'what Terraform pattern should I use', 'how would you structure this in Terraform', 'how do I handle X in Terraform'."
argument-hint: "<infrastructure to implement/refactor, module to design, or architecture question>"
effort: high
allowed-tools: "Read, Glob, Grep"
---

Generate idiomatic Terraform code or a Terraform architecture design. ultrathink

## Mode

Determine mode from the request:

- **Code mode** — user wants working HCL code ("implement", "write", "refactor", "add", "generate", "create module", "deploy")
- **Design mode** — user wants architectural guidance ("design", "architect", "how would you structure", "what pattern", "plan", "organize")

## Process

### 1. Walk the Decision Tree

Work through every section of the decision tree below that applies to the problem. A single problem often matches multiple branches — identify all that apply and note which N references are relevant.

### 2. Read Relevant References (optional)

If a matched branch is unfamiliar or the right approach is unclear, read its linked reference file. Each file explains: **when** to use the pattern, **how** it works, and includes an HCL snippet.

### 3. Research (if needed)

If the decision tree and references are not enough — e.g., unfamiliar provider resource, unclear best practice, need to compare approaches, or need latest docs — research the specific question before generating output.

### 4. Generate Output

**Code mode:** Produce valid, idiomatic Terraform 1.5+ HCL applying all identified patterns. Follow standard file naming (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `locals.tf`, `data.tf`, `providers.tf`, `backend.tf`). Every variable has `description` and `type`. Every output has `description`. Use `for_each` over `count` for collections. No hardcoded values. Preserve existing code style when refactoring. Do NOT run `terraform init`, `terraform plan`, or `terraform apply`.

**Design mode:** Output:

- Architecture issues found (if any) as a plain list — concrete problems with concrete fixes
- Directory and module structure
- State management strategy (backend, key design, isolation)
- Module input/output contracts (variable types, validation rules, outputs)
- Environment management approach
- Cross-configuration data flow pattern
- Trade-offs and rationale for each recommendation

---

## Always

These hold regardless of the specific problem:

- **Never use local state in production** — remote backend with locking, encryption, and versioning; state is the single most critical artifact
- **Split by blast radius** — separate configurations by domain and rate of change; a networking change should never risk a database
- **Use `for_each` over `count` for collections** — `count` is index-based; removing an item shifts all indices and triggers recreation of unrelated resources; use `count` only for boolean toggles (`0` or `1`)
- **No hardcoded values** — AMI IDs, subnet IDs, account IDs, and region-specific values belong in variables or data sources, not resource blocks
- **Protect stateful resources** — `prevent_destroy = true` on databases, encryption keys, and S3 buckets with important data
- **Commit `.terraform.lock.hcl`** — without it, different machines download different provider versions
- **Secrets never in state or code** — use ephemeral variables (TF 1.10+), Vault, OIDC; never hardcode credentials
- **Modules must be versioned** — pin to exact versions or narrow ranges in production; `source = "git::...?ref=v1.2.3"` or registry with version constraints
- **Every variable has `description` and `type`** — add `validation` blocks for inputs with constraints
- **Every output has `description`** — mark secrets with `sensitive = true`
- **Prefer declarative blocks** — `moved`, `import`, `removed` blocks over manual `terraform state` commands

---

## Decision Tree

### Is this a STATE MANAGEMENT problem?

- Team needs shared state with locking? [1](references/1-state-management.md)
  - AWS → S3 + DynamoDB backend
  - GCP → GCS backend (native locking)
  - Azure → Azure Blob Storage (blob leasing)
  - Multi-cloud / managed → HCP Terraform Cloud
- Plan/apply times > 3 minutes? → split state by domain and rate of change (microstack architecture) [1](references/1-state-management.md) [11](references/11-scaling-patterns.md)
- Frequent lock contention between team members? → split into smaller state files by component [1](references/1-state-management.md) [11](references/11-scaling-patterns.md)
- Secrets visible in state file? → ephemeral variables + write-only attributes (TF 1.10+) [5](references/5-variables-configuration.md) [10](references/10-security-patterns.md)
- State drift detected? → scheduled `terraform plan -detailed-exitcode` in CI [9](references/9-cicd-patterns.md)
- Need to share data between configurations?
  - Tight coupling OK (same team, same repo) → `terraform_remote_state` data source [7](references/7-data-flow.md)
  - Loose coupling (cross-team, cross-repo) → SSM Parameter Store publish/subscribe [7](references/7-data-flow.md) [11](references/11-scaling-patterns.md)

---

### Is this a MODULE DESIGN problem?

- Reusable resource group needed across 2+ configurations? → create a versioned module with clear input/output contract [2](references/2-module-design.md)
- Module has > 20 variables and > 500 lines? → split into focused L1/L2 modules, compose in root [2](references/2-module-design.md)
- Need to look up existing infrastructure (AMIs, VPCs, AZs)? → data-only module [2](references/2-module-design.md)
- Same infrastructure on AWS and GCP? → multi-cloud abstraction module with provider-specific submodules [2](references/2-module-design.md)
- Module needs multiple provider configurations (multi-region)? → `configuration_aliases` in `required_providers`; caller passes providers [6](references/6-provider-management.md)
- Should this be a module or inline resources? [2](references/2-module-design.md)
  - Used in 2+ places → module
  - Complex with clear contract → module
  - One-off, simple, < 5 resources → inline
- Module publishing?
  - Organization-wide reuse → private registry or Git with tags [2](references/2-module-design.md)
  - Single repo → local path `source = "../modules/vpc"` [2](references/2-module-design.md)
- Module composition? → dependency inversion — modules accept dependencies as inputs, don't create them [2](references/2-module-design.md)
- Standard module structure? → `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `locals.tf`, `data.tf`, `README.md`, `tests/`, `examples/` [2](references/2-module-design.md)

---

### Is this an ENVIRONMENT / ORGANIZATION problem?

- How to manage dev / staging / prod? [3](references/3-code-organization.md) [4](references/4-environment-management.md)
  - Small team, identical envs → workspaces + tfvars
  - Different resources per env → directory-based separation
- Need short-lived feature/preview environments? → workspaces + dynamic naming, create on PR open, destroy on merge [4](references/4-environment-management.md)
- Boilerplate duplicated across many environments? → Terragrunt with `include` and `dependency` blocks [11](references/11-scaling-patterns.md)
- Monorepo or polyrepo? [3](references/3-code-organization.md)
  - Shared modules, atomic cross-component changes → monorepo
  - Independent teams, independent release cycles → polyrepo
- Platform team providing self-service infra to app teams? → opinionated L2 modules with safe defaults [11](references/11-scaling-patterns.md)
- Directory structure? [3](references/3-code-organization.md)
  - Small project → flat structure
  - Most common → environment-based (`environments/dev/`, `environments/prod/`)
  - Large project → component-based (`components/networking/`, `components/compute/`)
  - DRY at scale → Terragrunt layout

---

### Is this a VARIABLE / CONFIGURATION problem?

- Input validation beyond type checking? → `validation` blocks in variables [5](references/5-variables-configuration.md)
- Cross-variable validation (TF 1.9+)? → `condition` can reference other variables [5](references/5-variables-configuration.md)
- Object attribute should be optional with a default? → `optional(type, default)` (TF 1.3+) [5](references/5-variables-configuration.md)
- Derived value from inputs? → `locals` block (not a variable) [5](references/5-variables-configuration.md)
- Secret in a variable? → `sensitive = true` (redacts CLI output only, still in state) [5](references/5-variables-configuration.md)
- Secret must never touch state? → `ephemeral = true` (TF 1.10+) [5](references/5-variables-configuration.md) [10](references/10-security-patterns.md)
- Repeated nested blocks within a resource? → dynamic blocks with `for_each` [5](references/5-variables-configuration.md)
- Multiple instances from a collection? → `for_each` with set or map [5](references/5-variables-configuration.md)
- Conditional resource creation (on/off toggle)? → `count = var.enabled ? 1 : 0` [5](references/5-variables-configuration.md)

---

### Is this a PROVIDER problem?

- Multi-region deployment? → provider aliases [6](references/6-provider-management.md)
- Multi-account deployment? → `assume_role` in provider blocks [6](references/6-provider-management.md)
- Module needs multiple provider configs? → `configuration_aliases` [6](references/6-provider-management.md)
- Provider version pinning? → `required_providers` in `versions.tf`, never in `provider` blocks [6](references/6-provider-management.md)

---

### Is this a DATA FLOW / DEPENDENCY problem?

- Resource depends on another but no attribute reference exists? → `depends_on` (avoid when possible; restructure to use attribute references) [7](references/7-data-flow.md)
- Need to query existing infrastructure? → data sources [7](references/7-data-flow.md)
- Need data from another Terraform configuration? [7](references/7-data-flow.md)
  - ⚠ `terraform_remote_state` exposes entire state → prefer SSM/Consul publish/subscribe
- Renaming or moving resources? → `moved` blocks (TF 1.1+) [7](references/7-data-flow.md)

---

### Is this a TESTING / VALIDATION problem?

- Input validation? → variable `validation` blocks + `precondition`/`postcondition` [8](references/8-testing-validation.md)
- Continuous infrastructure health checks? → `check` blocks (TF 1.5+) — warn, don't fail [8](references/8-testing-validation.md)
- Module contract testing? → native `terraform test` framework (TF 1.6+) with mock providers (TF 1.7+) [8](references/8-testing-validation.md)
- Full integration testing (real infrastructure)? → Terratest (Go) [8](references/8-testing-validation.md)
- Policy enforcement (security/compliance)? → Checkov (static) + OPA/Rego (plan JSON) + Sentinel (HCP TF) [8](references/8-testing-validation.md)

---

### Is this a CI/CD problem?

- Standard plan/apply workflow? → PR-based with OIDC auth [9](references/9-cicd-patterns.md)
- Drift detection? → scheduled `terraform plan -detailed-exitcode` [9](references/9-cicd-patterns.md)
- Need Terraform orchestration at scale? → Atlantis, Spacelift, env0, HCP Terraform [9](references/9-cicd-patterns.md)
- Cost estimation before apply? → Infracost in CI pipeline [9](references/9-cicd-patterns.md)
- Pre-commit hooks? → `pre-commit-terraform` (fmt, validate, tflint, docs, checkov) [9](references/9-cicd-patterns.md)

---

### Is this a SECURITY problem?

- CI/CD needs cloud provider access? → OIDC federation (no static credentials) [10](references/10-security-patterns.md)
- Resources need runtime secrets? [10](references/10-security-patterns.md)
  - Short-lived → Vault dynamic secrets
  - Must never touch state → ephemeral resources (TF 1.10+)
- Need to enforce security policies? [10](references/10-security-patterns.md)
  - Pre-plan (static analysis) → Checkov, tfsec/Trivy
  - Post-plan (plan JSON) → OPA/Rego
  - HCP Terraform → Sentinel policies
- IAM permissions for Terraform? → least privilege; separate plan (read-only) and apply (write) roles [10](references/10-security-patterns.md)
- Hardcoded credentials in code? → **never** — use OIDC, instance profiles, Vault, `random_password` [10](references/10-security-patterns.md)

---

### Is this a SCALING problem?

- State file > 200 resources? → split by domain and rate of change (microstack architecture) [11](references/11-scaling-patterns.md)
- Multiple teams modifying same state? → microstack with independent state files per component [11](references/11-scaling-patterns.md)
- Cross-configuration data sharing at scale? → dependency inversion via SSM parameters [11](references/11-scaling-patterns.md)
- Platform team providing golden path modules? → opinionated L2 modules with safe defaults [11](references/11-scaling-patterns.md)
- Terragrunt for DRY configurations? → `include`, `dependency`, and `inputs` blocks [11](references/11-scaling-patterns.md)

---

### Is this a RESOURCE LIFECYCLE problem?

- Resource needs zero-downtime replacement? → `create_before_destroy = true` [12](references/12-resource-lifecycle.md)
- Stateful resource must never be accidentally destroyed? → `prevent_destroy = true` [12](references/12-resource-lifecycle.md)
- External system modifies resource attributes? → `ignore_changes = [attribute]` [12](references/12-resource-lifecycle.md)
- Resource should be recreated when another changes? → `replace_triggered_by` [12](references/12-resource-lifecycle.md)
- Need to trigger scripts on change? → `terraform_data` (replaces `null_resource`) [12](references/12-resource-lifecycle.md)
- Provisioners? → avoid; prefer user data / cloud-init / Packer / config management [12](references/12-resource-lifecycle.md)

---

### Is this an IMPORT / MIGRATION problem?

- Import existing infrastructure? → `import` blocks (TF 1.5+) + `-generate-config-out` [13](references/13-import-migration.md)
- Bulk import? → `import` with `for_each` (TF 1.7+) [13](references/13-import-migration.md)
- Rename / move resources without destroy? → `moved` blocks (TF 1.1+) [13](references/13-import-migration.md)
- Remove from management without destroying? → `removed` blocks (TF 1.7+) with `destroy = false` [13](references/13-import-migration.md)
- Migrating between backends? → `terraform init -migrate-state` with backup first [13](references/13-import-migration.md)

---

### Is this a PERFORMANCE problem?

- Plan/apply times > 3 minutes? → split state (biggest impact — 70-90% reduction) [14](references/14-performance.md)
- Need to apply specific resources only? → `-target` (development only, not a workflow) [14](references/14-performance.md)
- State refresh consuming most of plan time? → `-refresh=false` when state is known current [14](references/14-performance.md)
- Hitting API rate limits? → reduce `-parallelism` (default 10) [14](references/14-performance.md)
- `for_each` over 1000+ items? → consider splitting the collection [14](references/14-performance.md)
