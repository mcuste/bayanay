# §7 — Data Flow & Dependencies

## When to Use

- Managing dependencies between resources
- Querying existing infrastructure with data sources
- Sharing data between separate Terraform configurations
- Renaming or moving resources in state

## How It Works

**Implicit dependencies (preferred):** Terraform builds a dependency graph from resource attribute references automatically. No extra configuration needed.

**Explicit dependencies (`depends_on`):** Use when there is a dependency Terraform cannot infer. Avoid when possible — it prevents parallelism and makes refactoring harder.

**Data sources:** Read from existing infrastructure without managing it. Refreshed on every plan.

**Cross-configuration data sharing:**

- **`terraform_remote_state`:** Requires read access to the entire state file (security risk). Use only for same-team, same-repo scenarios.
- **SSM Parameter Store / Consul (preferred):** Publish outputs to an external store, read with data sources. Decouples configurations without granting state access.
- **HCP Terraform `tfe_outputs`:** Reads only outputs, not the full state.

**Moved blocks (TF 1.1+):** Rename or relocate resources in state without destroy/recreate. Processed before plan creation. Leave in code for at least one release cycle.

## Code Snippet

```hcl
# Implicit dependency — subnet waits for VPC automatically
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id   # implicit dependency
  cidr_block = "10.0.1.0/24"
}

# Explicit dependency — use only when no attribute reference exists
resource "aws_instance" "app" {
  ami           = "ami-abc123"
  instance_type = "t3.micro"

  depends_on = [aws_iam_role_policy.app]
}

# Data source — query existing infrastructure
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Cross-config data sharing via SSM (preferred)
# Configuration A (networking) — publishes
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/infra/networking/vpc_id"
  type  = "String"
  value = aws_vpc.main.id
}

# Configuration B (compute) — consumes
data "aws_ssm_parameter" "vpc_id" {
  name = "/infra/networking/vpc_id"
}

resource "aws_instance" "web" {
  subnet_id = data.aws_ssm_parameter.vpc_id.value
}

# Moved blocks — rename without destroy
moved {
  from = aws_instance.web_server
  to   = aws_instance.app_server
}

moved {
  from = aws_instance.app_server
  to   = module.compute.aws_instance.app_server
}

moved {
  from = module.web
  to   = module.frontend
}
```
