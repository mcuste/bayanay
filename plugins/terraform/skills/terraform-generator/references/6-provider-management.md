# §6 — Provider Management

## When to Use

- Multi-region deployments requiring provider aliases
- Multi-account deployments with `assume_role`
- Modules that need multiple provider configurations
- Pinning provider versions for reproducibility

## How It Works

Always declare provider requirements in `versions.tf` using `required_providers`. Never use the deprecated `version` argument inside `provider` blocks.

**Provider aliases:** The unaliased provider block is the default. Resources without an explicit `provider` argument use it. Create aliases for additional regions or accounts.

**Multi-account pattern:** Use `assume_role` in provider blocks to operate across AWS accounts.

**Provider configuration in modules:** Child modules receive providers from parents implicitly. For aliased providers, use `configuration_aliases` in the module's `required_providers` and pass via the parent's `providers` map.

**Important limitation:** Terraform cannot run two different *versions* of the same provider simultaneously. Split into separate configurations if needed.

**Commit `.terraform.lock.hcl`** to version control — it locks exact provider versions and hashes across all platforms.

## Code Snippet

```hcl
# versions.tf — provider requirements
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

# Multi-region aliases
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "replica" {
  provider = aws.west
  bucket   = "myapp-replica-us-west-2"
}

# Multi-account with assume_role
provider "aws" {
  alias  = "production"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/TerraformRole"
  }
}

# Module with configuration_aliases
# Parent (root module)
module "multi_region_app" {
  source = "./modules/multi-region-app"

  providers = {
    aws.primary = aws
    aws.dr      = aws.west
  }
}

# Child module — versions.tf
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.dr]
    }
  }
}

# Child module — main.tf
resource "aws_instance" "primary" {
  provider = aws.primary
  # ...
}

resource "aws_instance" "dr" {
  provider = aws.dr
  # ...
}
```
