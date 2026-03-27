# §11 — Scaling Patterns

## When to Use

- State file > 200 resources or plan times > 3 minutes
- Multiple teams modifying the same state
- Need to share data between configurations at scale
- Platform team providing golden path modules
- Eliminating boilerplate across environments with Terragrunt

## How It Works

**Blast radius reduction:** Split configurations by rate of change and risk. Each component has its own state file, plan, and apply. A bad change to one component cannot destroy another.

**Guideline:** A single state file should manage fewer than ~200 resources.

**Microstack architecture:** Each independently deployable unit is a "stack" with its own state, CI/CD pipeline, and apply cadence. Cross-stack data flows via SSM parameters or published outputs.

**Shared services pattern:** Platform team owns core infrastructure. App teams consume via data sources or published outputs.

**Dependency inversion between configurations:** Both configurations interact through a neutral data store (SSM, Consul) instead of reading each other's state.

**Platform team abstractions:** Publish "golden path" modules with opinionated defaults. App teams get a simple, safe interface.

**Terragrunt:** Wraps Terraform to eliminate boilerplate across environments using `include`, `dependency`, and `inputs` blocks.

## Code Snippet

```text
# Microstack architecture — split by domain and rate of change
stacks/
  network-core/          # Low-change, high-risk
  security-baseline/     # Low-change, high-risk
  eks-platform/          # Medium-change, medium-risk
  data-platform/         # Low-change, high-risk
  app-team-a/            # High-change, low-risk
  app-team-b/            # High-change, low-risk
```

```hcl
# Shared services — platform team publishes
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/platform/networking/${var.environment}/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
}

# App team consumes
data "aws_ssm_parameter" "vpc_id" {
  name = "/platform/networking/${var.environment}/vpc_id"
}

module "app" {
  source = "./modules/ecs-service"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}

# Platform golden path module — simple interface
module "service" {
  source  = "app.terraform.io/mycompany/ecs-service/aws"
  version = "~> 3.0"

  name        = "payments-api"
  environment = "prod"
  image       = "123456789.dkr.ecr.us-east-1.amazonaws.com/payments:v1.2.3"
  cpu         = 512
  memory      = 1024
  port        = 8080
  # Everything else is opinionated defaults
}
```

```hcl
# Terragrunt — root config
# live/terragrunt.hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "mycompany-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# live/prod/eks/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

terraform {
  source = "../../../modules//eks"
}

inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids
}
```
