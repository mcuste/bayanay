# §10 — Security Patterns

## When to Use

- Configuring CI/CD authentication for Terraform
- Managing secrets in Terraform configurations
- Enforcing security policies across infrastructure
- Setting up least-privilege IAM for Terraform operations

## How It Works

**OIDC federation (no static credentials):** Replace long-lived `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` with OIDC. Tokens are short-lived, scoped by repo/branch/environment.

**Least privilege IAM:** CI/CD role should have only permissions needed for managed resources. Separate roles per configuration/environment.

**Vault integration:** Fetch dynamic secrets at plan time. Problem: fetched values stored in state. Solution: ephemeral resources (TF 1.10+).

**Ephemeral resources (TF 1.10+):** Values exist only during plan/apply — not persisted in state, plan files, or logs. Available in AWS, Azure, Kubernetes, and Google Cloud providers.

**Never hardcode credentials:**

- Provider auth → OIDC, instance profiles, environment variables
- Resource secrets → Vault, ephemeral resources, `random_password` with `sensitive = true`

## Code Snippet

```hcl
# OIDC provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_terraform" {
  name = "GitHubActionsTerraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:myorg/infra:*"
        }
      }
    }]
  })
}

# Ephemeral resource (TF 1.10+) — never written to state
ephemeral "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = "db.t3.medium"
  username       = "admin"
  password       = ephemeral.aws_secretsmanager_secret_version.db_password.secret_string
}

# Scoped IAM policy for CI/CD
data "aws_iam_policy_document" "terraform_ci" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "rds:*",
      "s3:*",
      "iam:GetRole", "iam:PassRole",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1", "us-west-2"]
    }
  }
}
```

```bash
# Security scanning pipeline
terraform fmt -check -recursive
terraform validate
checkov -d . --framework terraform
trivy config .
terraform plan -out=tfplan
terraform show -json tfplan | opa eval -i /dev/stdin -d policies/ "data.terraform.deny"
```
