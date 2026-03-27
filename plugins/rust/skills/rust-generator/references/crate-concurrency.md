# Crates: Concurrency

## dashmap

- **ALWAYS** use `dashmap` for concurrent maps under write contention

## flume

- **ALWAYS** use `flume` when channel must work in both sync and async

## parking_lot

- **ALWAYS** prefer `parking_lot::RwLock` over std when you need fairness or timeouts
