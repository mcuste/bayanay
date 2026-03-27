# §1 — State Management

## When to Use

- Any team or production Terraform deployment (never use local state in production)
- Multiple engineers working on the same infrastructure
- Infrastructure where state loss or corruption would cause data loss or drift
- Need to share data between configurations

## How It Works

State is the single most critical artifact in Terraform. The state file (`terraform.tfstate`) maps configuration resources to real-world objects, tracks metadata, and enables plan/apply diffing. Remote backends provide locking, team access, and durability. State locking prevents concurrent operations from corrupting state.

**Backend selection:**

- **S3 + DynamoDB (AWS):** S3 stores state; DynamoDB provides locking. Most common production backend.
- **GCS (Google Cloud):** GCS provides native object locking — no separate lock table needed.
- **Azure Blob Storage:** Uses blob leasing for state locking automatically.
- **HCP Terraform / Terraform Cloud:** Built-in locking, run history, policy enforcement, cost estimation, and drift detection.

**State key design:** Use a hierarchical structure mirroring infrastructure organization — `<domain>/<component>/terraform.tfstate`. One state file per independently deployable component.

**State isolation strategies:**

| Strategy              | When to Use                                   |
|-----------------------|-----------------------------------------------|
| Separate keys         | Small teams, simple setups                    |
| Separate buckets      | Stronger isolation, separate cloud accounts   |
| Separate accounts     | Enterprise — strongest blast radius reduction |

**Declarative state operations (TF 1.5+):** Prefer `moved`, `import`, and `removed` blocks over manual `terraform state` commands. Declarative blocks are reviewable, version-controlled, and executed within the plan/apply cycle.

## Code Snippet

```hcl
# S3 + DynamoDB backend (AWS)
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "networking/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Lock table setup
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# GCS backend
terraform {
  backend "gcs" {
    bucket = "mycompany-terraform-state"
    prefix = "networking/vpc"
  }
}

# HCP Terraform / Cloud
terraform {
  cloud {
    organization = "mycompany"
    workspaces {
      name = "networking-vpc-prod"
    }
  }
}
```

**Key commands:**

```bash
terraform state list                           # list all resources
terraform state show aws_instance.web          # show resource details
terraform state mv aws_instance.old aws_instance.new  # rename
terraform state pull > backup.json             # backup before surgery
terraform force-unlock <LOCK_ID>               # last resort for stuck locks
```
