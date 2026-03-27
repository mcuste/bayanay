# §3 — Code Organization

## When to Use

- Starting a new Terraform project and choosing directory structure
- Refactoring an existing project that has outgrown its structure
- Deciding between monorepo and polyrepo for infrastructure code

## How It Works

**File naming conventions** — split code into purpose-specific files:

| File           | Contents                                             |
|----------------|------------------------------------------------------|
| `main.tf`      | Primary resource definitions; module calls           |
| `variables.tf` | All `variable` blocks                                |
| `outputs.tf`   | All `output` blocks                                  |
| `providers.tf` | `provider` blocks and aliases                        |
| `versions.tf`  | `terraform { required_version, required_providers }` |
| `locals.tf`    | `locals` blocks for computed values                  |
| `data.tf`      | `data` source blocks                                 |
| `backend.tf`   | `terraform { backend { ... } }` (root module only)   |

For larger configurations, split `main.tf` by resource domain: `networking.tf`, `compute.tf`, `database.tf`, `iam.tf`.

**Monorepo vs polyrepo:**

| Aspect                      | Monorepo                              | Polyrepo                           |
|-----------------------------|---------------------------------------|------------------------------------|
| Cross-cutting refactors     | Single PR across all infra            | Coordination across repos          |
| Access control              | Coarse-grained (CODEOWNERS)           | Natural repo-level isolation       |
| Module sharing              | Relative paths, instant updates       | Git refs, explicit versioning      |
| Best for                    | Small-to-medium teams, single product | Large orgs, strong team boundaries |

**Recommendation:** Start with a monorepo. Split when teams exceed ~5-10 engineers working on infra simultaneously.

## Code Snippet

```text
# Flat Structure (Small Projects)
terraform/
  main.tf
  variables.tf
  outputs.tf
  providers.tf
  versions.tf
  terraform.tfvars

# Environment-Based (Most Common)
terraform/
  modules/
    vpc/
    eks/
    rds/
  environments/
    dev/
      main.tf
      terraform.tfvars
      backend.tf
    staging/
      main.tf
      terraform.tfvars
      backend.tf
    prod/
      main.tf
      terraform.tfvars
      backend.tf

# Component-Based (Large Projects)
terraform/
  modules/
    vpc/
    eks/
    rds/
  components/
    networking/
      main.tf
      backend.tf
    compute/
      main.tf
      backend.tf
    data/
      main.tf
      backend.tf
  environments/
    dev.tfvars
    staging.tfvars
    prod.tfvars

# Terragrunt Layout (DRY at Scale)
live/
  terragrunt.hcl
  dev/
    terragrunt.hcl
    vpc/
      terragrunt.hcl
    eks/
      terragrunt.hcl
  prod/
    terragrunt.hcl
    vpc/
      terragrunt.hcl
    eks/
      terragrunt.hcl
modules/
  vpc/
    main.tf
    variables.tf
    outputs.tf
```
