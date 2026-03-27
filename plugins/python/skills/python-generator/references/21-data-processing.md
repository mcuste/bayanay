# §21 — Data Processing Patterns

## When to Use

- Processing large datasets — Polars for production pipelines, Pandas for exploratory analysis
- Data transformation pipelines — generator expressions, `itertools` for lazy processing
- Chunked/batched processing — `itertools.batched` (3.12+)
- Larger-than-memory datasets — Polars streaming mode

## How It Works

**Polars** (Rust backend): Lazy evaluation with query optimization, multi-threaded, zero-copy where possible. Strict Arrow dtypes, native null handling. Use for production data pipelines and performance-critical work.

**Pandas**: Eager execution, single-threaded. Huge ecosystem, good for exploratory analysis in Jupyter. Loose types, `NaN`-based null handling.

**Generator pipelines**: Chain generators for lazy, memory-efficient data processing.

## Code Snippet

```python
import polars as pl
from itertools import batched

# Polars — lazy evaluation with optimization
result = (
    pl.scan_parquet("data/orders/*.parquet")
    .filter(pl.col("status") == "completed")
    .with_columns(
        pl.col("created_at").dt.month().alias("month"),
        (pl.col("quantity") * pl.col("unit_price")).alias("total"),
    )
    .group_by("customer_id", "month")
    .agg(
        pl.col("total").sum().alias("monthly_spend"),
        pl.col("order_id").n_unique().alias("order_count"),
    )
    .sort("monthly_spend", descending=True)
    .collect()  # execute optimized query plan
)

# Polars streaming — larger-than-memory datasets
(
    pl.scan_csv("huge_file.csv")
    .filter(pl.col("value") > 100)
    .group_by("category")
    .agg(pl.col("value").mean())
    .collect(streaming=True)
)

# Generator pipeline — lazy, memory-efficient
def read_records(path: str):
    with open(path) as f:
        for line in f:
            yield json.loads(line)

def filter_active(records):
    return (r for r in records if r["status"] == "active")

def transform(records):
    return ({"name": r["name"], "total": r["amount"] * r["qty"]} for r in records)

# Compose lazily — processes one record at a time
pipeline = transform(filter_active(read_records("data.jsonl")))
for batch in batched(pipeline, 100):  # 3.12+
    process_batch(batch)
```

## Notes

- **Polars** for production pipelines — lazy, multi-threaded, strict types
- **Pandas** for exploratory analysis, Jupyter, or when libraries only accept pandas
- Polars converts to/from pandas: `df.to_pandas()`, `pl.from_pandas(pdf)`
- `itertools.batched` (3.12+) replaces `[items[i:i+n] for i in range(0, len(items), n)]`
- Generator pipelines process one item at a time — O(1) memory regardless of dataset size
