# §13 — Import & Migration

## When to Use

- Importing existing infrastructure into Terraform management
- Bulk importing multiple resources
- Removing resources from management without destroying them
- Renaming or moving resources without destroy/recreate
- Migrating between backends
- Refactoring module structure

## How It Works

**Import blocks (TF 1.5+, declarative):** Reviewable, version-controlled, executed within plan/apply cycle. Supports `-generate-config-out` to auto-generate HCL matching the resource's actual state.

**Bulk import with `for_each` (TF 1.7+):** Import multiple resources from a map in a single block.

**Removed blocks (TF 1.7+):** Remove from Terraform management without destroying. `destroy = false` leaves resource untouched in cloud. `destroy = true` destroys and removes.

**Moved blocks (TF 1.1+):** Rename, move into/between modules, convert from `count` to `for_each`. Processed before plan creation.

**Backend migration:** Update backend config, run `terraform init -migrate-state`. Always backup state first.

**State surgery best practices:**
1. Always backup: `terraform state pull > backup.json`
2. Run `terraform plan` after — should show no changes
3. Never edit state JSON by hand
4. Prefer declarative blocks over CLI commands
5. One operation at a time

## Code Snippet

```hcl
# Import block (TF 1.5+)
import {
  to = aws_s3_bucket.existing
  id = "my-existing-bucket-name"
}

resource "aws_s3_bucket" "existing" {
  bucket = "my-existing-bucket-name"
}

# Bulk import with for_each (TF 1.7+)
locals {
  existing_buckets = {
    logs    = "company-logs-bucket"
    backups = "company-backups-bucket"
    assets  = "company-assets-bucket"
  }
}

import {
  for_each = local.existing_buckets
  to       = aws_s3_bucket.managed[each.key]
  id       = each.value
}

resource "aws_s3_bucket" "managed" {
  for_each = local.existing_buckets
  bucket   = each.value
}

# Removed block (TF 1.7+) — leave in cloud
removed {
  from = aws_instance.legacy_server

  lifecycle {
    destroy = false
  }
}

# Moved blocks — rename, restructure
moved {
  from = aws_s3_bucket.data
  to   = aws_s3_bucket.application_data
}

# Move from count to for_each
moved {
  from = aws_subnet.private[0]
  to   = aws_subnet.private["us-east-1a"]
}

# Move into a module
moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.main
}
```

```bash
# Generate config for imported resources
terraform plan -generate-config-out=generated.tf

# Migrate backends
terraform state pull > backup-$(date +%s).json
terraform init -migrate-state
terraform plan  # verify no changes
```
