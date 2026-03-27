# §9 — CI/CD Patterns

## When to Use

- Automating Terraform plan/apply workflows
- Setting up PR-based infrastructure deployment
- Detecting infrastructure drift
- Enforcing formatting and validation in CI
- Choosing a Terraform orchestration tool

## How It Works

**Standard workflow:** PR → `terraform fmt -check` → `terraform validate` → `terraform plan` → PR comment. Merge → `terraform apply` (with approval gate for prod).

**Critical rule:** Never `apply` from a developer laptop in production. All production applies go through CI/CD with audit trails.

**Drift detection:** Scheduled CI job running `terraform plan -detailed-exitcode`. Exit code 0 = no changes, 1 = error, 2 = drift detected.

**Orchestration tools:**

| Tool              | Model                  | Key Strengths                                                      |
|-------------------|------------------------|--------------------------------------------------------------------|
| Atlantis          | Self-hosted, PR-driven | Free, open-source, native VCS integration                          |
| HCP Terraform     | SaaS                   | Sentinel policies, cost estimation, drift detection                |
| Spacelift         | SaaS                   | Multi-IaC, native drift detection, OPA policies                   |
| env0              | SaaS                   | Cost management, RBAC, approval workflows                          |
| Terramate         | Open-source + SaaS     | Stack orchestration, change detection, GitOps-native               |

## Code Snippet

```yaml
# .github/workflows/terraform.yml
name: Terraform
on:
  pull_request:
    paths: ['terraform/**']
  push:
    branches: [main]
    paths: ['terraform/**']

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsTerraform
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform fmt -check -recursive
      - run: terraform validate
      - run: terraform plan -out=tfplan

  apply:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsTerraform
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform apply -auto-approve
```

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.96.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
      - id: terraform_checkov
```

```bash
# Drift detection (scheduled CI job)
terraform plan -detailed-exitcode
# Exit code: 0 = no changes, 1 = error, 2 = changes detected

# Cost estimation
infracost breakdown --path .
infracost diff --path .
```
