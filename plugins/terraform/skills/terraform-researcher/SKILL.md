---
name: terraform-researcher
description: "Research Terraform ecosystem, providers, modules, cloud platforms, CI/CD pipelines, and infrastructure tooling — fetches latest official docs and returns structured findings. Use when: 'research this Terraform provider', 'look up Terraform docs for', 'what's the latest on', 'find Terraform examples of', 'compare these Terraform modules', 'how does X work in Terraform'."
argument-hint: "<topic, provider, module, tool, or question to research>"
effort: high
allowed-tools: "WebSearch, WebFetch, Read"
---

Research Terraform ecosystem, cloud providers, modules, CI/CD tooling, security patterns, and infrastructure platforms from authoritative sources. ultrathink

## Process

1. **Understand the query** — Determine what needs researching: provider resource API, module design, state management, CI/CD configuration, security pattern, scaling strategy, testing approach, migration guide, tool comparison, etc.

2. **Search and fetch** — Use WebSearch to find relevant sources, then WebFetch to read the actual content. Read the relevant reference URL file(s) for authoritative sources to check first. Always fetch multiple sources to cross-reference.

   **Reference URLs** — read only the file(s) matching the query topic:
   - Terraform language, state, modules, providers, HCL syntax: [urls-terraform-core.md](references/urls-terraform-core.md)
   - AWS, GCP, Azure Terraform providers and cloud docs: [urls-cloud-providers.md](references/urls-cloud-providers.md)
   - terraform test, Checkov, OPA, Sentinel, Terratest, tfsec: [urls-testing-policy.md](references/urls-testing-policy.md)
   - GitHub Actions, Atlantis, Spacelift, env0, HCP Terraform, pre-commit: [urls-cicd-orchestration.md](references/urls-cicd-orchestration.md)
   - Terragrunt, tflint, Infracost, terraform-docs, scaling patterns: [urls-scaling-tooling.md](references/urls-scaling-tooling.md)
   - Vault, OIDC, secrets management, ephemeral resources, compliance: [urls-security.md](references/urls-security.md)

   - **Always fetch latest version docs** unless a specific version is requested. Use the canonical HashiCorp developer docs (`developer.hashicorp.com/terraform/`) over legacy URLs. If the user's configuration targets an older Terraform version, still research latest — but note any breaking changes or feature availability differences between their version and latest.

   **Local module sources** — when you need the exact API of a module or provider in use:
   - Read `versions.tf` / `providers.tf` first to find required provider versions
   - Read `terraform.lock.hcl` for the exact provider versions locked
   - Check `.terraform/modules/` for downloaded module source (after `terraform init`)
   - Read `main.tf`, `variables.tf`, `outputs.tf` for the module's public interface
   - Check `examples/` directories in module repos for usage patterns
   - For workspace-local modules, read source directly from the workspace

3. **Output** — Return structured findings:

   ```text
   Topic: <what was researched>

   Findings:
   - <finding 1>
   - <finding 2>

   Sources:
   - <url 1> — <what it covers>
   - <url 2> — <what it covers>
   ```

   - Lead with actionable findings, not background
   - Include code examples when relevant — use HCL code blocks
   - Note version-specific information (e.g., "as of Terraform 1.10", "requires provider aws >= 5.0")
   - Flag conflicting advice between sources
   - NEVER use markdown tables (`| ... |`) anywhere in output
