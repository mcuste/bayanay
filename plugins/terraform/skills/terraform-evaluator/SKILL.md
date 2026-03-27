---
name: terraform-evaluator
description: "Evaluate Terraform code for idiomatic patterns and architecture. Use when: 'review Terraform code', 'check if this Terraform is idiomatic', 'evaluate Terraform patterns', 'audit Terraform architecture', 'does this Terraform code follow best practices', 'review these Terraform files'."
argument-hint: "<file path(s), code, or git diff>"
effort: high
allowed-tools: "Read, Glob, Grep, TodoWrite"
---

Evaluate Terraform code against the decision tree from the terraform-generator skill. ultrathink

## Process

1. **Read the Code** — Read all files provided. If given a directory or glob, discover `.tf` files and `*.tfvars`.

2. **Select Categories & Create Checklist** — Determine which of the 12 decision tree categories apply (Always rules always apply). Create a TodoWrite checklist with **one TODO per applicable category**, listing all rule IDs in that category. Do NOT output anything to the user during this step — category selection is internal. Example:

   ```text
   - [ ] Always: always-remote-state, always-blast-radius, always-for-each, ...
   - [ ] State Management: state-remote-backend, state-split, state-lock-contention, ...
   - [ ] Module Design: mod-versioned, mod-split, mod-composition, ...
   ```

3. **Check Rules** — Work through the TODO list **one category at a time**. The entire checking process is internal — do NOT output ANY text to the user during this step (no summaries, no "all clean" per category, no skip reasons, no reasoning). For each category:
   1. Mark the category as `in_progress`.
   2. Evaluate **every rule by ID** in that category against every file. For each rule, decide: violation or clean.
   3. Mark the category as `completed`.

   Rules for checking:
   - **When in doubt, skip it.** Only flag a rule when the violation is unambiguous — any competent Terraform reviewer would agree it applies. A missed violation is acceptable. If you find yourself weighing pros and cons of whether a rule applies, it is not clear enough to flag.
   - **Be exhaustive.** When a rule is violated in multiple locations, list **every** occurrence with its line number — do not summarize as "throughout the file" or pick representative examples.
   - If a matched rule is unfamiliar or the right approach is unclear, read its linked reference file from the terraform-generator skill at `${CLAUDE_SKILL_DIR}/../terraform-generator/references/`.

4. **Output** — This is the ONLY step that produces user-visible output. List all violations grouped by category. If all clean, output `All clean — no violations found.`

   - Only report violations, NEVER suggestions — if a rule does not clearly apply, skip it
   - NEVER explain skipped categories or clean categories — omit them entirely
   - NEVER use markdown tables (`| ... |`) anywhere in output

   Format:

   ```text
   STATE MANAGEMENT
   - [state-split] file:line — description
   - [state-secrets-in-state] file:line — description

   MODULE DESIGN
   - [mod-versioned] file:line — description

   N violations found.
   ```

---

## Always

These hold regardless of the specific problem — flag any violation.

- `always-remote-state` **Never use local state in production** — remote backend with locking, encryption, and versioning; state is the single most critical artifact
- `always-blast-radius` **Split by blast radius** — separate configurations by domain and rate of change; a networking change should never risk a database
- `always-for-each` **Use `for_each` over `count` for collections** — `count` is index-based; removing an item shifts all indices and triggers recreation of unrelated resources; use `count` only for boolean toggles (`0` or `1`)
- `always-no-hardcoded` **No hardcoded values** — AMI IDs, subnet IDs, account IDs, and region-specific values belong in variables or data sources, not resource blocks
- `always-protect-stateful` **Protect stateful resources** — `prevent_destroy = true` on databases, encryption keys, and S3 buckets with important data
- `always-lock-hcl` **Commit `.terraform.lock.hcl`** — without it, different machines download different provider versions
- `always-no-secrets` **Secrets never in state or code** — use ephemeral variables (TF 1.10+), Vault, OIDC; never hardcode credentials
- `always-module-versioned` **Modules must be versioned** — pin to exact versions or narrow ranges in production; `source = "git::...?ref=v1.2.3"` or registry with version constraints
- `always-var-description` **Every variable has `description` and `type`** — add `validation` blocks for inputs with constraints
- `always-output-description` **Every output has `description`** — mark secrets with `sensitive = true`
- `always-declarative` **Prefer declarative blocks** — `moved`, `import`, `removed` blocks over manual `terraform state` commands

---

## Decision Tree

### Is this a STATE MANAGEMENT problem?

- `state-remote-backend` Team needs shared state with locking? → S3+DynamoDB / GCS / Azure Blob / HCP Terraform Cloud [1](../terraform-generator/references/1-state-management.md)
- `state-split` Plan/apply times > 3 minutes or state > 200 resources? → split state by domain and rate of change (microstack architecture) [1](../terraform-generator/references/1-state-management.md) [11](../terraform-generator/references/11-scaling-patterns.md)
- `state-lock-contention` Frequent lock contention between team members? → split into smaller state files by component [1](../terraform-generator/references/1-state-management.md) [11](../terraform-generator/references/11-scaling-patterns.md)
- `state-secrets-in-state` Secrets visible in state file? → ephemeral variables + write-only attributes (TF 1.10+) [5](../terraform-generator/references/5-variables-configuration.md) [10](../terraform-generator/references/10-security-patterns.md)
- `state-drift` State drift detected? → scheduled `terraform plan -detailed-exitcode` in CI [9](../terraform-generator/references/9-cicd-patterns.md)
- `state-data-sharing` Need to share data between configurations? [7](../terraform-generator/references/7-data-flow.md)
  - Tight coupling OK (same team, same repo) → `terraform_remote_state` data source
  - Loose coupling (cross-team, cross-repo) → SSM Parameter Store publish/subscribe [11](../terraform-generator/references/11-scaling-patterns.md)

---

### Is this a MODULE DESIGN problem?

- `mod-versioned` Module source not pinned to specific version? → pin to exact versions or narrow ranges [2](../terraform-generator/references/2-module-design.md)
- `mod-split` Module has > 20 variables and > 500 lines? → split into focused L1/L2 modules, compose in root [2](../terraform-generator/references/2-module-design.md)
- `mod-data-only` Need to look up existing infrastructure (AMIs, VPCs, AZs)? → data-only module [2](../terraform-generator/references/2-module-design.md)
- `mod-multi-provider` Module needs multiple provider configurations (multi-region)? → `configuration_aliases` in `required_providers`; caller passes providers [6](../terraform-generator/references/6-provider-management.md)
- `mod-inline-vs-module` Should this be a module or inline? → 2+ places or complex with clear contract → module; one-off simple < 5 resources → inline [2](../terraform-generator/references/2-module-design.md)
- `mod-composition` Module creating its own dependencies internally? → dependency inversion — modules accept dependencies as inputs, don't create them [2](../terraform-generator/references/2-module-design.md)
- `mod-structure` Non-standard module file structure? → `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `locals.tf`, `data.tf` [2](../terraform-generator/references/2-module-design.md)

---

### Is this an ENVIRONMENT / ORGANIZATION problem?

- `env-management` How to manage dev / staging / prod? [3](../terraform-generator/references/3-code-organization.md) [4](../terraform-generator/references/4-environment-management.md)
  - Small team, identical envs → workspaces + tfvars
  - Different resources per env → directory-based separation
- `env-boilerplate` Boilerplate duplicated across many environments? → Terragrunt with `include` and `dependency` blocks [11](../terraform-generator/references/11-scaling-patterns.md)
- `env-directory` Non-standard directory structure for project size? [3](../terraform-generator/references/3-code-organization.md)
  - Small project → flat structure
  - Most common → environment-based (`environments/dev/`, `environments/prod/`)
  - Large project → component-based (`components/networking/`, `components/compute/`)

---

### Is this a VARIABLE / CONFIGURATION problem?

- `var-validation` Input needs validation beyond type checking? → `validation` blocks in variables [5](../terraform-generator/references/5-variables-configuration.md)
- `var-optional-default` Object attribute should be optional with a default? → `optional(type, default)` (TF 1.3+) [5](../terraform-generator/references/5-variables-configuration.md)
- `var-derived` Derived value defined as a variable instead of a local? → `locals` block [5](../terraform-generator/references/5-variables-configuration.md)
- `var-secret` Secret in a variable without `sensitive = true`? → mark sensitive [5](../terraform-generator/references/5-variables-configuration.md)
- `var-ephemeral` Secret must never touch state? → `ephemeral = true` (TF 1.10+) [5](../terraform-generator/references/5-variables-configuration.md) [10](../terraform-generator/references/10-security-patterns.md)
- `var-dynamic` Repeated nested blocks within a resource? → dynamic blocks with `for_each` [5](../terraform-generator/references/5-variables-configuration.md)
- `var-count-collection` Using `count` to create multiple instances from a collection? → `for_each` with set or map [5](../terraform-generator/references/5-variables-configuration.md)
- `var-conditional` Conditional resource creation? → `count = var.enabled ? 1 : 0` (only valid `count` use for collections) [5](../terraform-generator/references/5-variables-configuration.md)

---

### Is this a PROVIDER problem?

- `prov-multi-region` Multi-region deployment? → provider aliases [6](../terraform-generator/references/6-provider-management.md)
- `prov-multi-account` Multi-account deployment? → `assume_role` in provider blocks [6](../terraform-generator/references/6-provider-management.md)
- `prov-version-pinning` Provider version not pinned in `required_providers`? → pin in `versions.tf`, never in `provider` blocks [6](../terraform-generator/references/6-provider-management.md)

---

### Is this a DATA FLOW / DEPENDENCY problem?

- `data-depends-on` Using `depends_on` when attribute references would work? → restructure to use attribute references [7](../terraform-generator/references/7-data-flow.md)
- `data-remote-state` Using `terraform_remote_state` exposing entire state? → prefer SSM/Consul publish/subscribe [7](../terraform-generator/references/7-data-flow.md) [11](../terraform-generator/references/11-scaling-patterns.md)
- `data-moved` Renaming or moving resources with manual state commands? → `moved` blocks (TF 1.1+) [7](../terraform-generator/references/7-data-flow.md)

---

### Is this a TESTING / VALIDATION problem?

- `test-input-validation` Input has constraints not enforced by type? → variable `validation` blocks + `precondition`/`postcondition` [8](../terraform-generator/references/8-testing-validation.md)
- `test-check-blocks` Need continuous infrastructure health checks? → `check` blocks (TF 1.5+) — warn, don't fail [8](../terraform-generator/references/8-testing-validation.md)
- `test-native` Module needs contract testing? → native `terraform test` framework (TF 1.6+) with mock providers (TF 1.7+) [8](../terraform-generator/references/8-testing-validation.md)
- `test-policy` Need security/compliance enforcement? → Checkov (static) + OPA/Rego (plan JSON) + Sentinel (HCP TF) [8](../terraform-generator/references/8-testing-validation.md)

---

### Is this a CI/CD problem?

- `cicd-workflow` Standard plan/apply workflow? → PR-based with OIDC auth [9](../terraform-generator/references/9-cicd-patterns.md)
- `cicd-drift` No drift detection? → scheduled `terraform plan -detailed-exitcode` [9](../terraform-generator/references/9-cicd-patterns.md)
- `cicd-cost` No cost estimation before apply? → Infracost in CI pipeline [9](../terraform-generator/references/9-cicd-patterns.md)
- `cicd-precommit` No pre-commit hooks? → `pre-commit-terraform` (fmt, validate, tflint, docs, checkov) [9](../terraform-generator/references/9-cicd-patterns.md)

---

### Is this a SECURITY problem?

- `sec-oidc` CI/CD using static credentials for cloud provider access? → OIDC federation [10](../terraform-generator/references/10-security-patterns.md)
- `sec-runtime-secrets` Resources need runtime secrets? [10](../terraform-generator/references/10-security-patterns.md)
  - Short-lived → Vault dynamic secrets
  - Must never touch state → ephemeral resources (TF 1.10+)
- `sec-policy` No security policy enforcement? [10](../terraform-generator/references/10-security-patterns.md)
  - Pre-plan (static analysis) → Checkov, tfsec/Trivy
  - Post-plan (plan JSON) → OPA/Rego
  - HCP Terraform → Sentinel policies
- `sec-iam` IAM permissions too broad for Terraform? → least privilege; separate plan (read-only) and apply (write) roles [10](../terraform-generator/references/10-security-patterns.md)
- `sec-hardcoded-creds` Hardcoded credentials in code? → **never** — use OIDC, instance profiles, Vault, `random_password` [10](../terraform-generator/references/10-security-patterns.md)

---

### Is this a SCALING problem?

- `scale-state-size` State file > 200 resources? → split by domain and rate of change (microstack architecture) [11](../terraform-generator/references/11-scaling-patterns.md)
- `scale-multi-team` Multiple teams modifying same state? → microstack with independent state files per component [11](../terraform-generator/references/11-scaling-patterns.md)
- `scale-data-sharing` Cross-configuration data sharing at scale? → dependency inversion via SSM parameters [11](../terraform-generator/references/11-scaling-patterns.md)
- `scale-platform` Platform team providing golden path modules? → opinionated L2 modules with safe defaults [11](../terraform-generator/references/11-scaling-patterns.md)
- `scale-terragrunt` Terragrunt for DRY configurations? → `include`, `dependency`, and `inputs` blocks [11](../terraform-generator/references/11-scaling-patterns.md)

---

### Is this a RESOURCE LIFECYCLE problem?

- `lifecycle-create-before-destroy` Resource needs zero-downtime replacement? → `create_before_destroy = true` [12](../terraform-generator/references/12-resource-lifecycle.md)
- `lifecycle-prevent-destroy` Stateful resource without `prevent_destroy`? → `prevent_destroy = true` on databases, encryption keys, S3 buckets [12](../terraform-generator/references/12-resource-lifecycle.md)
- `lifecycle-ignore-changes` External system modifies resource attributes? → `ignore_changes = [attribute]` [12](../terraform-generator/references/12-resource-lifecycle.md)
- `lifecycle-replace-triggered` Resource should be recreated when another changes? → `replace_triggered_by` [12](../terraform-generator/references/12-resource-lifecycle.md)
- `lifecycle-null-resource` Using `null_resource`? → `terraform_data` (replaces `null_resource`) [12](../terraform-generator/references/12-resource-lifecycle.md)
- `lifecycle-provisioner` Using provisioners? → avoid; prefer user data / cloud-init / Packer / config management [12](../terraform-generator/references/12-resource-lifecycle.md)

---

### Is this an IMPORT / MIGRATION problem?

- `import-cli` Using `terraform import` CLI command? → `import` blocks (TF 1.5+) + `-generate-config-out` [13](../terraform-generator/references/13-import-migration.md)
- `import-bulk` Bulk import without `for_each`? → `import` with `for_each` (TF 1.7+) [13](../terraform-generator/references/13-import-migration.md)
- `import-moved` Using `terraform state mv` to rename/move? → `moved` blocks (TF 1.1+) [13](../terraform-generator/references/13-import-migration.md)
- `import-removed` Using `terraform state rm` to remove from management? → `removed` blocks (TF 1.7+) with `destroy = false` [13](../terraform-generator/references/13-import-migration.md)
- `import-backend-migration` Migrating between backends? → `terraform init -migrate-state` with backup first [13](../terraform-generator/references/13-import-migration.md)

---

### Is this a PERFORMANCE problem?

- `perf-split-state` Plan/apply times > 3 minutes? → split state (biggest impact — 70-90% reduction) [14](../terraform-generator/references/14-performance.md)
- `perf-target` Using `-target` in production workflows? → development only, not a workflow [14](../terraform-generator/references/14-performance.md)
- `perf-parallelism` Hitting API rate limits? → reduce `-parallelism` (default 10) [14](../terraform-generator/references/14-performance.md)
- `perf-large-for-each` `for_each` over 1000+ items? → consider splitting the collection [14](../terraform-generator/references/14-performance.md)
