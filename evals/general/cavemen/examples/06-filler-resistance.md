Docker networking has two main modes: bridge and host.

**Bridge (default):**

- Docker creates isolated virtual network for containers
- Each container gets own IP on internal subnet (172.17.0.0/16 default)
- Containers talk to each other via bridge network, outside world via NAT
- Port mapping required: `-p 8080:80` maps host port → container port
- Isolation = good for security, multi-container setups

**Host:**

- Container shares host network stack directly
- No isolation — container binds host ports directly
- No NAT overhead → slightly better perf
- Port conflicts possible if host already using same port
- `-p` flag ignored, container owns host's network interfaces

**When to use what:**

- Bridge → most cases. Isolation, predictable networking, compose setups
- Host → perf-sensitive apps (high-throughput, low-latency), or container needs full network access

```bash
# bridge (default)
docker run -p 8080:80 nginx

# host
docker run --network host nginx
```

Key difference: bridge isolates + requires port mapping, host shares network stack directly. Bridge for safety, host for speed.
