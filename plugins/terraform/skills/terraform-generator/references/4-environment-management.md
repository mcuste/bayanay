# §4 — Environment Management

## When to Use

- Managing multiple deployment environments (dev, staging, prod)
- Creating short-lived feature/preview environments
- Deciding between workspaces and directory-based separation
- Implementing environment promotion strategies

## How It Works

**Workspaces vs directory separation:**

| Aspect               | Workspaces                                    | Directory Separation                            |
|----------------------|-----------------------------------------------|-------------------------------------------------|
| Code duplication     | None — single codebase                        | Some — mitigated by shared modules              |
| Divergence           | Hard — conditional logic pollutes code        | Easy — each env can differ naturally            |
| Risk                 | Applying to wrong workspace is common         | Directory structure prevents cross-env mistakes |
| Best for             | Ephemeral/dynamic environments                | Long-lived environments (dev, staging, prod)    |

**Recommendation:** Directory separation for long-lived environments. Workspaces for ephemeral/dynamic environments.

**Environment parity:** Keep environments as similar as possible — same modules, same providers, same structure. Only scale (instance sizes, replica counts) should differ.

**Promotion strategies:**

1. **Git-based (recommended):** Feature branch → PR against main (plan on dev) → merge (apply to dev) → tag release (apply to staging) → promote to prod with approval gate.
2. **Module version promotion:** Publish module version → dev pins immediately → staging pins after dev validation → prod pins after staging validation.

## Code Snippet

```hcl
# Workspace-based configuration (ephemeral environments)
resource "aws_instance" "web" {
  instance_type = terraform.workspace == "prod" ? "m5.xlarge" : "t3.micro"

  tags = {
    Environment = terraform.workspace
  }
}

# Feature environments — dynamic naming
locals {
  env_name = var.feature_branch != "" ? "feature-${var.feature_branch}" : var.environment
}

resource "aws_ecs_service" "app" {
  name = "${local.env_name}-app"
}
```

```hcl
# prod.tfvars — environment-specific values
environment    = "prod"
instance_type  = "m5.xlarge"
min_capacity   = 3
max_capacity   = 10
enable_waf     = true
alert_email    = "oncall@company.com"
```

```bash
# Apply with environment-specific tfvars
terraform plan -var-file="environments/prod.tfvars"
```
