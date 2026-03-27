---
name: terraform-lint
description: Lint Terraform code — run fmt, validate, tflint, trivy, and checkov. Use when asked to lint, check, audit, or validate a Terraform project.
argument-hint: "<terraform directory>"
model: haiku
allowed-tools: "Bash(bash **/run-lints.sh)"
---

# Terraform Lint

## Run

```bash
bash ${CLAUDE_SKILL_DIR}/run-lints.sh
```

## Summary

Summarize the output. One line per finding:

```text
- [validate] Error: Missing required provider "aws"
- [tflint] main.tf:12 — aws_instance_invalid_type: "t2.micro2" is invalid
- [trivy:HIGH] modules/s3/main.tf:5 — AVD-AWS-0086: S3 bucket encryption not configured
- [checkov:CKV_AWS_18] main.tf:20 — Ensure the S3 bucket has access logging enabled
- [fmt] formatting check failed
```

Drop progress messages, download output, and informational text — only violations.

If the output is empty or all clean: `All lints clean.`
