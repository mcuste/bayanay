# Concurrency & Async

## Interior Mutability

- [conc-escalate-sync] ALWAYS escalate: `Cell` → `RefCell` → `AtomicXxx` → `Mutex` → `RwLock` (prefer `Mutex` unless profiling shows read contention)
- [conc-no-guard-return] NEVER return `MutexGuard` from functions unless deliberate projected-view API
- [conc-minimal-lock] ALWAYS keep lock scopes minimal — clone out, drop guard, operate; exception: expensive clones
- [conc-lock-order] ALWAYS lock multiple mutexes in consistent documented order
- [conc-no-lock-send] NEVER hold lock while sending on channel

## Async Mutex

- [conc-std-mutex-async] ALWAYS default to `std::sync::Mutex` in async code — `tokio::sync::Mutex` only when held across `.await`

## Async State

- [conc-async-state] ALWAYS design shared async state as `Clone + Send + Sync + 'static`

## select! vs spawn

- [conc-select-cancel] ALWAYS use `select!` when one completing should cancel others
- [conc-spawn-independent] ALWAYS use `tokio::spawn` for independent long-lived work
- [conc-no-cpu-tokio] NEVER spawn CPU-bound work on tokio runtime — use `spawn_blocking`

## Channels

- [conc-oneshot] ALWAYS use `oneshot` for single request/response
- [conc-watch] ALWAYS use `watch` for latest-value-only shared state
- [conc-notify] ALWAYS prefer `tokio::sync::Notify` over channel-based signaling for wake-without-data
- [conc-cancel-token] ALWAYS prefer `CancellationToken` over `broadcast` for shutdown
- [conc-no-unbounded] NEVER use unbounded channels without explicit justification
- [conc-owned-send] ALWAYS prefer sending owned data through channels over `Arc`-wrapping when sender doesn't need data after send

## Tracing Integration

- [conc-instrument-spawn] ALWAYS instrument spawned futures with `.instrument(span)`

## Cancellation Safety

- [conc-no-cancel-unsafe-select] NEVER place non-cancel-safe futures in `select!` arms — wrap in `tokio::spawn`
- [conc-doc-cancel-safety] ALWAYS document cancellation safety of public async functions used in `select!`

## Structured Concurrency

- [conc-joinset] ALWAYS prefer `JoinSet` over `FuturesUnordered` for spawned tasks
- [conc-futures-unordered] ALWAYS prefer `FuturesUnordered` for local concurrency without spawning
- [conc-no-drop-handle] NEVER drop `JoinHandle` expecting cancellation — call `.abort()`

## Concurrency Limiting

- [conc-semaphore] ALWAYS prefer `tokio::sync::Semaphore` over manual `AtomicUsize` for concurrency limiting
- [conc-semaphore-owned] ALWAYS prefer `Semaphore::acquire_owned` when permit must outlive semaphore borrow

## Pinning

- [conc-biased-select] ALWAYS use `biased;` in `tokio::select!` when one branch must be checked first
- [conc-pin-macro] ALWAYS prefer `std::pin::pin!()` over `Box::pin()` when future consumed in same scope

## Actor Pattern

- [conc-actor-spawn-in-ctor] ALWAYS spawn actor task inside handle constructor
- [conc-actor-bounded] ALWAYS use bounded channels for actor mailboxes
- [conc-no-actor-cycles] NEVER create bounded channel cycles between actors
- [conc-actor-sender-drop] ALWAYS rely on sender-drop for shutdown; explicit shutdown message before dropping for graceful drain

## Concurrency Crates

- [conc-dashmap] ALWAYS use `dashmap` for concurrent maps under write contention
- [conc-flume] ALWAYS use `flume` when channel must work in both sync and async
- [conc-parking-lot] ALWAYS prefer `parking_lot::RwLock` over std when you need fairness or timeouts
