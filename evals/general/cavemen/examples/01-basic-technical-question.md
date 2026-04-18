DB index = data structure that speeds up row lookups. Without index → DB scans every row (full table scan) → slow on big tables.

Think: book index. Instead of reading every page to find "polymorphism," flip to back, get page number, jump direct.

**When to use:**

- Columns in `WHERE`, `JOIN`, `ORDER BY` frequently → index them
- High-cardinality columns (many unique values) → big speedup
- Read-heavy tables → indexes shine

**When to skip:**

- Small tables → full scan already fast
- Write-heavy tables → each `INSERT`/`UPDATE`/`DELETE` must update index too → overhead
- Low-cardinality columns (e.g., boolean) → index barely helps

**Types:**

- **B-tree** — default in most DBs. Good for range queries (`>`, `<`, `BETWEEN`)
- **Hash** — exact match only (`=`). Faster for equality, no range support
- **Composite** — multi-column index. Column order matters; leftmost prefix rule applies

```sql
CREATE INDEX idx_users_email ON users (email);
```

Rule of thumb: index columns you query often, measure with `EXPLAIN`, avoid over-indexing. Each index costs storage + write perf.
