Common causes of 401 with valid JWT:

1. **Auth middleware strips `Bearer` prefix wrong.** Check if code does `token = header.split(' ')[1]` — off-by-one or missing space → empty token → 401.

2. **Secret mismatch.** jwt.io validates signature only if you paste correct secret. Server-side secret in env differs from signing secret → signature verification fails → 401. Check `JWT_SECRET` env var matches what issued token.

3. **Algorithm mismatch.** Token signed with RS256 but server expects HS256 (or vice versa). Verify `algorithm` param in `jwt.verify()`.

4. **Token expired.** jwt.io shows decoded payload but doesn't reject expired tokens by default. Check `exp` claim against current server time. Clock skew between servers → silent expiry.

5. **Header not forwarded.** Proxy/nginx strips `Authorization` header. Add `proxy_set_header Authorization $http_authorization;` to nginx config.

6. **Case sensitivity.** `authorization` vs `Authorization` — Express normalizes to lowercase. If middleware reads `req.headers['Authorization']` → undefined → 401. Use `req.headers['authorization']` or `req.get('Authorization')`.

Debug steps:
- Log `req.headers` in auth middleware before token check → confirm header arrives
- Wrap `jwt.verify()` in try/catch → log exact error msg (expired? invalid signature? malformed?)
- Compare `process.env.JWT_SECRET` at runtime vs token signing secret
