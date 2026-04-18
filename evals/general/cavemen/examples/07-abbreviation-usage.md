Set env vars in Dockerfile or `docker-compose.yml`. Two approaches:

**1. Dockerfile `ENV`:**

```dockerfile
ENV DATABASE_HOST=db
ENV DATABASE_PORT=5432
ENV DATABASE_NAME=myapp
```

Baked into image → not ideal for secrets. Use for defaults only.

**2. docker-compose (preferred):**

```yaml
services:
  app:
    image: myapp
    env_file:
      - .env
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - AUTH_SECRET=${AUTH_SECRET}
```

`env_file` loads from `.env` file → keeps config out of compose file. Inline `environment` overrides env_file values.

**DB config pattern:**

App reads env vars at startup. Standard env naming:

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `AUTH_TOKEN_SECRET`, `AUTH_EXPIRY`

**Auth params → app:**

Pass as env vars same way. App picks up from `std::env` / `os.environ` / `process.env` depending on language.

```bash
docker run -e DB_HOST=localhost -e DB_PASSWORD=secret -e AUTH_SECRET=abc123 myapp
```

**Secrets handling:**

Never put auth secrets in Dockerfile or image. Use:
- Docker secrets (Swarm mode)
- `.env` file excluded from repo (`.gitignore`)
- Runtime injection via CI/CD

Config hierarchy: Dockerfile defaults → env_file → `environment` block → cmd line `-e` flags. Later overrides earlier.

Keep DB config and auth params in `.env`, mount at runtime → twelve-factor app pattern. Rebuild not needed for config changes.
