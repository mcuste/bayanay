# §5 — Variables & Configuration

## When to Use

- Defining module or root configuration inputs
- Validating user-provided values
- Computing derived values
- Handling sensitive values and secrets
- Using dynamic blocks, `for_each`, or `count`

## How It Works

**Variable types:** `string`, `number`, `bool`, `list(type)`, `map(type)`, `set(type)`, `object({...})`, `tuple([...])`. Use `optional(type, default)` (TF 1.3+) for object attributes with defaults.

**Locals vs variables:** If it is a user choice → variable. If it is a computation → local.

**Sensitive variables:** `sensitive = true` redacts CLI output but value is still in state. For true secret protection use ephemeral variables (TF 1.10+) or Vault.

**Ephemeral variables (TF 1.10+):** `ephemeral = true` prevents the value from being written to state or plan files. Can only flow to other ephemeral contexts.

**Variable precedence (lowest to highest):** Default → `TF_VAR_name` → `terraform.tfvars` → `*.auto.tfvars` → `-var-file` → `-var`.

**`for_each` vs `count`:**

| | `count` | `for_each` |
|---|---|---|
| Index type | Integer | String key |
| Reordering | Shifts indices, causes recreate | Keys are stable |
| Best for | Boolean toggles (`0` or `1`) | Multiple instances from map/set |

## Code Snippet

```hcl
# Structural types with optional attributes
variable "instance" {
  type = object({
    type     = string
    ami      = string
    key_name = optional(string, null)
  })
}

# Validation blocks
variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR notation (e.g., 10.0.0.0/16)."
  }
}

# Locals — derived values
variable "project" { type = string }
variable "environment" { type = string }

locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Ephemeral variable (TF 1.10+)
variable "session_token" {
  type      = string
  ephemeral = true
}

# Dynamic blocks
variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}

# for_each — stable keys
resource "aws_subnet" "private" {
  for_each = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
    "us-east-1c" = "10.0.3.0/24"
  }

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value
}

# count — boolean toggle only
resource "aws_cloudwatch_log_group" "app" {
  count = var.enable_logging ? 1 : 0
  name  = "/app/${var.name}"
}
```
