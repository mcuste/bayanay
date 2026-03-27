# §14 — Performance & Optimization

## When to Use

- `terraform plan` takes > 2-3 minutes
- State file contains > 200 resources
- Hitting cloud API rate limits during plan/apply
- Need to iterate quickly during development

## How It Works

**State splitting (biggest impact):** Organizations report 70-90% reduction in plan/apply times by splitting monolithic state into components. This is the single most impactful optimization.

**Targeted applies:** `terraform apply -target=resource` applies only specific resources. Development/debugging tool, not a workflow — can leave state inconsistent. Always run full plan after.

**Refresh optimization:** State refresh (querying cloud APIs) often consumes 90%+ of plan time. `-refresh=false` skips this — useful when only changing locals or outputs. Caution: cannot detect drift.

**Refresh-only plan:** `terraform plan -refresh-only` updates state without changing resources. Reconciles drift.

**Parallelism tuning:** Default is 10. Increase for large independent deployments. Decrease if hitting API rate limits. Effective parallelism limited by dependency graph.

**Large state management:**
- Move rarely-changed resources to separate state files
- Avoid `for_each` over 1000+ items (each becomes a separate state object)
- Use `-refresh=false` during development iterations

## Code Snippet

```bash
# Default parallelism
terraform apply -parallelism=20    # increase for many independent resources
terraform apply -parallelism=5     # decrease if hitting API rate limits

# Skip refresh when state is known current
terraform plan -refresh=false

# Refresh-only — update state, no resource changes
terraform plan -refresh-only
terraform apply -refresh-only

# Targeted apply (development only)
terraform apply -target=aws_instance.web
terraform apply -target=module.networking

# Multiple targets
terraform plan -target=aws_security_group.web -target=aws_instance.web

# After targeted operations, always run full plan
terraform plan
```

**Indicators for state splitting:**
- `terraform plan` > 2-3 minutes
- State file > 200 resources
- Multiple teams on same state
- Frequent lock contention

**Split strategy:**
```text
# High-change, low-risk (daily)
components/app-service/

# Medium-change, medium-risk
components/compute/
components/monitoring/

# Low-change, high-risk
components/networking/
components/iam/
components/database/
```
