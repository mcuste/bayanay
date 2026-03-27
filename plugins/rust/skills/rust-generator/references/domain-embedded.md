## Domain: Embedded

- **ALWAYS** follow PAC → HAL → BSP layering; direct register access only when HAL lacks feature or ISR needs it
- **ALWAYS** use typestate for peripheral config; `DynPin` when mode changes at runtime
- **ALWAYS** choose concurrency by latency: RTIC (hard real-time) → Embassy (cooperative async) → RTOS (porting threaded code)
- **NEVER** use Embassy for sub-ms deadline guarantees
- **NEVER** assume `alloc` in `no_std` — set up `#[global_allocator]` explicitly
