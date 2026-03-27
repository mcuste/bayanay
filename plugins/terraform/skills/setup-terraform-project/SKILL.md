---
name: setup-terraform-project
description: "Set up a Terraform project — TFLint linting and Checkov security scanning based on providers, resources, and desired strictness level. Use when: 'set up Terraform project', 'configure tflint', 'configure checkov', 'Terraform linting setup', 'Terraform project setup'."
argument-hint: "<project or module path>"
---

# Setup Terraform Project

You are setting up a Terraform project's linting and security scanning. Use `AskUserQuestion` to gather information step by step. Generate configuration by reading and adapting the preset files in `references/` (relative to this skill file).

## Reference Files

| File                        | Purpose                                            |
|-----------------------------|----------------------------------------------------|
| `tflint-chill.hcl`          | TFLint: recommended preset only, no style rules    |
| `tflint-medium.hcl`         | TFLint: all rules, naming + docs as warnings       |
| `tflint-strict.hcl`         | TFLint: all rules, key rules promoted to error     |
| `tflint-plugin-aws.hcl`     | AWS provider plugin stanza                         |
| `tflint-plugin-azurerm.hcl` | Azure provider plugin stanza                       |
| `tflint-plugin-google.hcl`  | GCP provider plugin stanza                         |
| `checkov-chill.yaml`        | Checkov: soft-fail all, hard-fail on critical only |
| `checkov-medium.yaml`       | Checkov: all checks, noisy ones soft-fail          |
| `checkov-strict.yaml`       | Checkov: all checks, only false positives skipped  |

## Step 0: Scan the Project

Before asking questions, scan the project to detect its configuration automatically. This step is silent — do not show results to the user yet, just gather the data for later steps.

1. **Detect providers** — search `*.tf` files for `provider` blocks and `required_providers` entries:
   - `provider "aws"` or `aws = { source = "hashicorp/aws"` → AWS
   - `provider "azurerm"` or `azurerm = { source = "hashicorp/azurerm"` → Azure
   - `provider "google"` or `google = { source = "hashicorp/google"` → GCP
   - Note any other providers found (e.g., `kubernetes`, `helm`, `datadog`)

2. **Detect module structure** — check for:
   - Terraform workspace root (has `backend` block or `.terraform/` directory)
   - Shared module (has `variable` + `output` blocks but no `backend`)
   - Monorepo (multiple directories with `*.tf` files)

3. **Detect existing config** — check for:
   - `.tflint.hcl` — existing TFLint config (offer to update vs replace)
   - `.checkov.yaml` / `.checkov.yml` — existing Checkov config
   - `.pre-commit-config.yaml` — existing pre-commit hooks

4. **Detect resource types** — grep for `resource "` blocks to understand what categories of Checkov checks are relevant (S3, RDS, IAM, networking, etc.)

Store these findings for use in Steps 1–4.

## Step 1: Project Info

Present the scan results as a summary, then call `AskUserQuestion` with 4 questions:

**Summary format:**
> Detected: **{providers}** provider(s), **{resource_count}** resource types, **{structure}** layout.
> Existing config: {list any existing .tflint.hcl, .checkov.yaml, .pre-commit-config.yaml found, or "none"}

**Question 1** — "What are you configuring?", header: "Scope", multiSelect: false

- "Single Terraform root module" — one working directory with a backend
- "Shared module (no backend)" — reusable module consumed by other roots
- "Monorepo — apply to all modules" — config at repo root, used by all subdirectories

**Question 2** — "Confirm detected providers (deselect any that are wrong):", header: "Providers", multiSelect: true

- List each detected provider as a pre-selected option
- Add "Other — I'll specify" as a non-selected option

**Question 3** — "Any compliance requirements?", header: "Compliance", multiSelect: true

- "CIS Benchmarks"
- "SOC2"
- "HIPAA"
- "PCI-DSS"
- "None"

**Question 4** — "Which tools do you want to set up?", header: "Tools", multiSelect: true

- "TFLint — linting, naming conventions, provider-specific validation (Recommended)"
- "Checkov — security scanning, encryption, IAM, public access checks (Recommended)"

Skip configuration for any tool the user deselects. The comparison table and adjustments in later steps still reference both tools — only show rows/options relevant to the selected tools.

Wait for answers before proceeding.

## Step 2: Strictness Level

Present the comparison tables for each selected tool, then ask for a strictness level per tool in a single `AskUserQuestion` call. Only show questions for tools the user selected in Step 1.

### TFLint comparison

|                           | Chill                  | Medium         | Strict                           |
|---------------------------|------------------------|----------------|----------------------------------|
| **Bundled preset**        | recommended (13 rules) | all (20 rules) | all (20 rules)                   |
| **Naming conventions**    | Off                    | Warning        | Error                            |
| **Documentation rules**   | Off                    | Warning        | Warning                          |
| **Unused declarations**   | Warning                | Warning        | Error                            |
| **Provider/version pins** | Warning                | Warning        | Error                            |
| **Module structure**      | Off                    | Warning        | Error                            |
| **Provider plugin**       | Enabled                | Enabled        | Enabled                          |
| **Best for**              | Prototypes, iteration  | Most projects  | Shared modules, production infra |

### Checkov comparison

|                           | Chill                             | Medium                      | Strict                       |
|---------------------------|-----------------------------------|-----------------------------|------------------------------|
| **Mode**                  | Soft-fail all, hard-fail critical | All checks, noisy soft-fail | All checks, only FPs skipped |
| **Encryption checks**     | Hard-fail                         | Enforced                    | Enforced                     |
| **IAM checks**            | Hard-fail                         | Enforced                    | Enforced                     |
| **Network security**      | Hard-fail (SSH/RDP only)          | Enforced                    | Enforced                     |
| **Logging/monitoring**    | Advisory                          | Soft-fail (warn)            | Enforced                     |
| **Data protection**       | Advisory                          | Soft-fail (warn)            | Enforced                     |
| **Governance/tagging**    | Advisory                          | Advisory                    | Enforced                     |
| **Known false positives** | Skipped                           | Skipped                     | Skipped                      |
| **Best for**              | Dev/staging, iteration            | Most production projects    | Regulated, compliance-driven |

Call `AskUserQuestion` with one question per selected tool:

**Question 1** (if TFLint selected) — "TFLint strictness level?", header: "TFLint", multiSelect: false

- "Chill — catch bugs and deprecations, stay out of the way"
- "Medium — all rules with naming and documentation (Recommended)"
- "Strict — maximum enforcement, key rules are errors"

**Question 2** (if Checkov selected) — "Checkov strictness level?", header: "Checkov", multiSelect: false

- "Chill — critical security only, everything else advisory"
- "Medium — broad security coverage, noisy checks as warnings (Recommended)"
- "Strict — maximum coverage, only false positives skipped"

Wait for answers before proceeding.

## Step 3: Project-Specific Adjustments

Based on the scan results from Step 0 and answers from Step 1, present **only the relevant** adjustments below. Combine all applicable adjustments into a single `AskUserQuestion` with multiSelect: true. Pre-select recommended options with "(Recommended)" suffix.

### If Shared module (no backend)

- "Enforce standard module structure — main.tf, variables.tf, outputs.tf (Recommended)" — set `terraform_standard_module_structure` to `error` (or add if chill preset)
- "Require variable and output descriptions (Recommended)" — enable `terraform_documented_variables` and `terraform_documented_outputs` as `warning` (or promote to `error` for strict)

### If Monorepo

- "Enable recursive scanning — TFLint scans all subdirectories (Recommended)" — note that `tflint --recursive` should be used in CI
- "Place config at repo root — all modules inherit (Recommended)"

### If Compliance requirements selected

- "Enable Checkov compliance framework scanning (Recommended)" — add `--framework terraform --check CIS` or equivalent to the Checkov config. For strict, also add the framework-specific checks.

### If AWS provider detected

- "Add AWS-specific Checkov skip list for common false positives (Recommended)" — add AWS-specific noisy checks to skip/soft-fail list based on detected resources:
  - If S3 resources: skip `CKV_AWS_144` (cross-region replication), soft-fail `CKV_AWS_145` (CMK vs SSE-S3)
  - If VPC/networking resources: soft-fail `CKV2_AWS_5` (unrestricted egress), `CKV_AWS_130` (public subnet IPs)

### If Azure provider detected

- "Add Azure-specific Checkov skip list (Recommended)" — skip `CKV_AZURE_36` (dynamic content FPs), `CKV2_AZURE_31` (special subnet FPs)

### If GCP provider detected

- "Add GCP-specific Checkov skip list (Recommended)" — skip `CKV_GCP_73` (dynamic rule FPs)

### General adjustments (always ask in a second call)

Call `AskUserQuestion` with these questions:

**Question 1** — "Do you use Terraform Cloud or Enterprise?", header: "Backend", multiSelect: false

- "Yes — remote backend / Terraform Cloud" — add `terraform_workspace_remote` awareness note; for Checkov, skip plan-based checks that need local plan output
- "No — local / S3 / GCS / AzureRM backend"

**Question 2** — "How do you manage module sources?", header: "Modules", multiSelect: false (skip if no module calls detected)

- "Terraform Registry" — enforce `terraform_module_version` as error
- "Git repositories" — enforce `terraform_module_pinned_source` as error
- "Local paths only" — no module source rules needed
- "Mix of registry and git"

## Step 4: Generate & Apply

### Build the configuration

1. Read the reference preset files for the chosen levels:
   - `references/tflint-{level}.hcl` — base TFLint config
   - `references/tflint-plugin-{provider}.hcl` — one per detected provider
   - `references/checkov-{level}.yaml` — base Checkov config

2. Apply all adjustments from Step 3 to the preset content.

3. Assemble the final `.tflint.hcl`:
   - Start with the base preset (plugin "terraform" block + rule overrides)
   - Append each detected provider's plugin block
   - Add any rule overrides from Step 3 adjustments

4. Assemble the final `.checkov.yaml`:
   - Start with the base preset
   - Add/remove provider-specific skip-check and soft-fail-on entries based on detected providers and resources
   - Remove check IDs for providers not in use (e.g., remove all `CKV_AZURE_*` entries if Azure is not detected)

### Review

Show the user both generated configs in a single response:

1. **`.tflint.hcl`** — the complete config file
2. **`.checkov.yaml`** — the complete config file
3. **CI commands** — the recommended commands for CI integration:

   ```bash
   # TFLint
   tflint --init && tflint

   # Checkov
   checkov -d . --config-file .checkov.yaml
   ```

Call `AskUserQuestion`:

**Question** — "What would you like to do?", header: "Apply", multiSelect: false

- "Apply all — write config files"
- "Make adjustments first" — ask what to change, regenerate, re-prompt
- "Just show me — I'll apply myself"

### If "Apply all"

1. Write `.tflint.hcl` to project root (or update existing — merge plugin blocks, don't duplicate)
2. Write `.checkov.yaml` to project root (or update existing)
3. Run `tflint --init` to install plugins
4. Run `tflint` to show current violations
5. Run `checkov -d . --config-file .checkov.yaml --compact` to show current violations
6. Call `AskUserQuestion` — "Linting found violations. What would you like to do?", header: "Violations", multiSelect: false
   - "Show me a summary" — present a categorized summary of findings by severity
   - "Address critical issues now" — work through error-severity violations together
   - "Leave for now" — done

## Step 5: CI Integration

Check if `.github/workflows/` or similar CI config exists. If found, suggest adding linting steps.

Present the recommended CI pipeline order:

```text
1. terraform fmt -check          # formatting (fast, no init needed)
2. terraform init -backend=false # initialize providers (no backend needed for linting)
3. terraform validate            # syntax + schema
4. tflint --init && tflint       # linting (provider-specific)
5. checkov -d . --config-file .checkov.yaml  # security scan
```

Call `AskUserQuestion` — "Would you like to set up CI integration?", header: "CI", multiSelect: false

- "Yes — generate GitHub Actions workflow" — create `.github/workflows/terraform-lint.yml` with the pipeline above
- "Yes — just show me the commands" — print the commands for manual CI setup
- "Skip — I'll handle CI myself"

### If GitHub Actions

Generate a workflow file that:

- Triggers on pull requests touching `*.tf` files
- Installs Terraform, TFLint, and Checkov
- Runs the 5-step pipeline above
- Uses `tflint-plugin-aws` (or appropriate provider) action for caching
