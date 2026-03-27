# §8 — Testing & Validation

## When to Use

- Validating inputs beyond type checking
- Asserting resource state before/after apply
- Monitoring infrastructure health continuously
- Testing module contracts
- Enforcing security and compliance policies

## How It Works

**Testing pyramid (fastest to slowest):**

1. **`terraform validate`** — syntax, types, internal references. No cloud credentials needed.
2. **Variable `validation` blocks** — constrain user-provided values.
3. **`precondition` / `postcondition`** — validate resource state before/after apply.
4. **`check` blocks (TF 1.5+)** — non-blocking health checks, produce warnings.
5. **`terraform test` (TF 1.6+)** — module contract testing with real or mocked infrastructure.
6. **Terratest (Go)** — full integration testing with programmatic assertions.
7. **Policy as code** — Checkov (static), OPA/Rego (plan JSON), Sentinel (HCP TF).

**Mock providers (TF 1.7+):** Enable unit testing without cloud API calls.

**`check` blocks** run as the last step of plan/apply. Failed checks warn but don't prevent apply. In HCP Terraform, they enable continuous validation.

## Code Snippet

```hcl
# Precondition — validate BEFORE creation
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    precondition {
      condition     = data.aws_ami.selected.architecture == "x86_64"
      error_message = "AMI must be x86_64 architecture."
    }

    postcondition {
      condition     = self.public_ip != ""
      error_message = "Instance did not receive a public IP."
    }
  }
}

# Check block (TF 1.5+) — non-blocking health check
check "website_health" {
  data "http" "app" {
    url = "https://${aws_lb.main.dns_name}/health"
  }

  assert {
    condition     = data.http.app.status_code == 200
    error_message = "Application health check failed."
  }
}
```

```hcl
# tests/basic.tftest.hcl — native test framework (TF 1.6+)
variables {
  environment = "test"
  vpc_cidr    = "10.99.0.0/16"
}

# Plan-only test — no real infrastructure
run "validates_cidr_input" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.99.0.0/16"
    error_message = "VPC CIDR did not match input."
  }
}

# Test invalid input — expects validation failure
run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "invalid"
  }

  expect_failures = [
    var.environment
  ]
}

# Mock providers (TF 1.7+)
mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id           = "ami-mock123"
      architecture = "x86_64"
    }
  }
}
```

```bash
# Run tests
terraform test
terraform test -filter=tests/basic.tftest.hcl
terraform test -verbose

# Policy scanning
checkov -d . --framework terraform
trivy config .
```
