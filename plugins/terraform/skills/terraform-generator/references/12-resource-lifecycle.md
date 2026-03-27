# §12 — Resource Lifecycle

## When to Use

- Resources need zero-downtime replacement
- Protecting stateful resources from accidental destruction
- External systems modify resource attributes after creation
- Resources should be recreated when another resource changes
- Running scripts or provisioners on resource change

## How It Works

**`create_before_destroy`:** New resource created before old one destroyed. Use for zero-downtime replacement (launch templates, DNS records, certificates). Caveat: propagates to all dependencies automatically.

**`prevent_destroy`:** Terraform refuses to destroy the resource. Use on databases, encryption keys, S3 buckets with important data. Does NOT protect against removing the resource block entirely.

**`ignore_changes`:** Terraform ignores specified attribute changes during plan. Use when external systems modify attributes (auto-scaling adjustments, deployment pipelines). `ignore_changes = all` for creation/destruction-only management.

**`replace_triggered_by`:** Force resource replacement when another resource changes. Can only reference managed resources, not variables. Use `terraform_data` to bridge.

**`terraform_data`:** Stores arbitrary values in state and can trigger replacements. Built-in (no provider dependency), replaces `null_resource` for new code.

**Provisioners:** Last resort. Not captured in plan, not idempotent, poor failure handling. Prefer user data / cloud-init / Packer / config management tools.

## Code Snippet

```hcl
# create_before_destroy — zero-downtime replacement
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}

# prevent_destroy — protect stateful resources
resource "aws_db_instance" "production" {
  identifier     = "prod-database"
  engine         = "postgres"
  instance_class = "db.r6g.xlarge"

  lifecycle {
    prevent_destroy = true
  }
}

# ignore_changes — external system manages this attribute
resource "aws_autoscaling_group" "app" {
  desired_capacity = 3

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# replace_triggered_by — cascade replacement
resource "aws_instance" "sidecar" {
  ami           = var.sidecar_ami_id
  instance_type = "t3.micro"

  lifecycle {
    replace_triggered_by = [aws_instance.web.id]
  }
}

# terraform_data — replacement trigger from variable
resource "terraform_data" "replacement_trigger" {
  input = var.revision
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  lifecycle {
    replace_triggered_by = [terraform_data.replacement_trigger]
  }
}

# Timeouts for slow resources
resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = "db.r6g.xlarge"

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}
```
