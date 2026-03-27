## Domain: Systems

- **ALWAYS** prefer generational indices (`slotmap`) over `Rc<RefCell<T>>` for cyclic structures; `Box<Node>` for small heterogeneous trees
- **ALWAYS** use `bytes::Bytes`/`BytesMut` for multi-stage network pipelines; `Vec<u8>` for simple request/response
- **NEVER** use thread-per-core runtimes unless profiling proves cross-thread sync is bottleneck
