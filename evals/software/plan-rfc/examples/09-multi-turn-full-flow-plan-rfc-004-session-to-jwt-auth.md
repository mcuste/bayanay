# PLAN-RFC-004: Session-to-JWT Auth Migration

**RFC**: RFC-004
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `package.json` | Modify | Add `jsonwebtoken@^9.0.2`, `@types/jsonwebtoken@^9.0.9`; post-cleanup remove `connect-pg-simple`, `@types/connect-pg-simple` |
| `src/types/express.d.ts` | Modify | Augment `Express.Request` with `user?: { id: string; email: string; roles: string[] }` |
| `src/lib/jwt.ts` | Create | Export `signToken(payload)` and `verifyToken(token)` wrappers — HS256, 15-min expiry, `JWT_SECRET` env |
| `src/middleware/auth.ts` | Modify | Replace session-only check with dual-path `AUTH_MODE`-driven JWT/session logic |
| `src/routes/auth.ts` | Modify | Update `/login` handler to issue JWT via `signToken` when `AUTH_MODE` is `hybrid` or `jwt` |
| `docs/adr/ADR-XXX-jwt-session-auth.md` | Create | Record JWT as application session, HS256 signing, 15-min expiry, rejected Redis-sessions and big-bang alternatives |

---

## Phase 1 — Core

*Walking skeleton: dual-path middleware deployed with `AUTH_MODE=session` (Phase 1 inert deploy). Project compiles, all 50 existing endpoints continue to work via session path, no behavior change.*

### M1: Add `jsonwebtoken` dependency to `package.json`

In `package.json`, add `"jsonwebtoken": "^9.0.2"` to `dependencies` and `"@types/jsonwebtoken": "^9.0.9"` to `devDependencies`. Run `npm install` to update the lockfile.

**Acceptance Criteria**

- `npm install` exits 0.
- `import jwt from 'jsonwebtoken'` in a TypeScript file compiles without errors.

---

### M2: Augment `Express.Request` with `user` property in `src/types/express.d.ts`

Open (or create) `src/types/express.d.ts`. Add a global namespace augmentation declaring `user` on `Express.Request`:

```typescript
declare global {
  namespace Express {
    interface Request {
      user?: { id: string; email: string; roles: string[] };
    }
  }
}
export {};
```

If the file already augments `Express.Request`, merge the `user` field into the existing interface block rather than adding a second `interface Request` declaration.

**Acceptance Criteria**

- TypeScript compiles after the change.
- `req.user?.id`, `req.user?.email`, and `req.user?.roles` resolve without type errors in any Express handler file.

---

### M3: Create `src/lib/jwt.ts` — `signToken` and `verifyToken` wrappers

Create `src/lib/jwt.ts` exporting two functions:

```typescript
import jwt, { JwtPayload } from 'jsonwebtoken';

export interface TokenPayload {
  sub: string;
  email: string;
  roles: string[];
}

export function signToken(payload: TokenPayload): string {
  return jwt.sign(payload, process.env.JWT_SECRET!, {
    algorithm: 'HS256',
    expiresIn: '15m',
  });
}

export function verifyToken(token: string): TokenPayload {
  const decoded = jwt.verify(token, process.env.JWT_SECRET!, {
    algorithms: ['HS256'],
  }) as JwtPayload;
  return {
    sub: decoded.sub!,
    email: decoded.email,
    roles: decoded.roles,
  };
}
```

No startup guard, no error handling — happy path only. `JWT_SECRET` runtime validation is added in M8.

**Acceptance Criteria**

- Module compiles; `import { signToken, verifyToken } from './lib/jwt'` resolves without errors.
- `signToken({ sub: 'u1', email: 'a@b.com', roles: ['user'] })` returns a string with exactly three dot-separated segments.
- `verifyToken(signToken({ sub: 'u1', email: 'a@b.com', roles: ['user'] }))` returns an object with matching `sub`, `email`, and `roles`.

---

### M4: Replace `src/middleware/auth.ts` with dual-path `AUTH_MODE` logic

Replace the existing session-only middleware body in `src/middleware/auth.ts` with the dual-path implementation from RFC-004. Import `jwt` and `JwtPayload` from `jsonwebtoken` directly (not via `src/lib/jwt.ts` — that module is for the login route). Keep the existing `getUserFromSession` import.

```typescript
import jwt, { JwtPayload } from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';
import { getUserFromSession } from '../lib/session';

export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  const AUTH_MODE = process.env.AUTH_MODE ?? 'session';

  if (
    authHeader?.startsWith('Bearer ') &&
    (AUTH_MODE === 'jwt' || AUTH_MODE === 'hybrid')
  ) {
    try {
      const token = authHeader.slice(7);
      const payload = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
      req.user = { id: payload.sub!, email: payload.email, roles: payload.roles };
      return next();
    } catch {
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }
  }

  if (AUTH_MODE === 'session' || AUTH_MODE === 'hybrid') {
    if (req.session?.userId) {
      req.user = await getUserFromSession(req.session.userId);
      return next();
    }
  }

  res.status(401).json({ error: 'Authentication required' });
}
```

Adjust the `getUserFromSession` import path to match the existing location in the project.

**Acceptance Criteria**

- With `AUTH_MODE` unset or `session`: a request with a valid session cookie proceeds to `next()` with `req.user` populated — identical to pre-RFC behavior.
- With `AUTH_MODE=session`: same as above.
- TypeScript compiles; `npm run build` exits 0.

---

### M5: Update `/login` in `src/routes/auth.ts` to issue JWT when `AUTH_MODE=hybrid|jwt`

In the `/login` POST handler in `src/routes/auth.ts`, after successful credential validation, branch on `process.env.AUTH_MODE`:

- If `hybrid` or `jwt`: call `signToken({ sub: user.id, email: user.email, roles: user.roles })` from `src/lib/jwt`, return HTTP 200 `{ token }`. Do not create a PostgreSQL session.
- Otherwise (`session` or unset): keep existing session-creation path unchanged.

```typescript
import { signToken } from '../lib/jwt';

// Inside the /login handler, after credential validation:
const AUTH_MODE = process.env.AUTH_MODE ?? 'session';
if (AUTH_MODE === 'hybrid' || AUTH_MODE === 'jwt') {
  const token = signToken({ sub: user.id, email: user.email, roles: user.roles });
  res.json({ token });
  return;
}
// existing session creation path
```

**Acceptance Criteria**

- `POST /login` with valid credentials and `AUTH_MODE=hybrid` returns HTTP 200 with body `{ "token": "<string>" }` where the token has three dot-separated segments.
- `POST /login` with valid credentials and `AUTH_MODE=session` returns HTTP 200 with a session cookie set (existing behavior unchanged, no `token` field in response body).
- TypeScript compiles.

---

## Phase 2 — Details

### M6: Tighten JWT verification error handling in `src/middleware/auth.ts`

Replace the bare `catch` in the Bearer token path with typed error handling. Catch `jwt.TokenExpiredError` and `jwt.JsonWebTokenError` explicitly and return 401. Re-throw anything else so programming errors aren't swallowed.

```typescript
    } catch (err) {
      if (err instanceof jwt.TokenExpiredError || err instanceof jwt.JsonWebTokenError) {
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
      }
      throw err;
    }
```

**Acceptance Criteria**

- A Bearer token with an invalid signature returns HTTP 401 `{ "error": "Invalid or expired token" }`.
- A Bearer token with a past `exp` claim returns HTTP 401 `{ "error": "Invalid or expired token" }`.
- A non-JWT error thrown inside the try block (e.g., `TypeError`) propagates to the Express error handler rather than returning HTTP 401.

---

### M7: Validate required JWT claims after verify in `src/middleware/auth.ts`

After `jwt.verify` succeeds and the result is cast to `JwtPayload`, assert `payload.sub`, `payload.email`, and `payload.roles` are all truthy before assigning to `req.user`. If any are missing, return 401.

```typescript
      const payload = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
      if (!payload.sub || !payload.email || !payload.roles) {
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
      }
      req.user = { id: payload.sub, email: payload.email, roles: payload.roles };
```

This also removes the non-null assertion (`payload.sub!`) from the `req.user` assignment.

**Acceptance Criteria**

- A valid HS256 token missing the `email` claim returns HTTP 401 `{ "error": "Invalid or expired token" }`.
- A valid HS256 token missing the `roles` claim returns HTTP 401 `{ "error": "Invalid or expired token" }`.
- A valid HS256 token containing `sub`, `email`, and `roles` results in `next()` being called with `req.user.id === payload.sub`.

---

### M8: Guard against missing `JWT_SECRET` at module load in `src/lib/jwt.ts`

At the top of `src/lib/jwt.ts`, after imports, add a startup-time check:

```typescript
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required');
}
```

This causes the process to crash immediately at startup rather than issuing tokens with a missing secret or throwing obscure errors on the first request.

**Acceptance Criteria**

- Starting the application without `JWT_SECRET` set causes the process to throw an error whose message contains `'JWT_SECRET environment variable is required'` before handling any requests.
- Starting the application with `JWT_SECRET` set proceeds without error.

---

### M9: Create `docs/adr/ADR-XXX-jwt-session-auth.md`

Create the ADR file using the `software:adr` skill. It must record:

- **Status**: Accepted
- **Context**: PostgreSQL sessions table is a per-request read bottleneck at 10k concurrent users (~5-10ms per request); horizontal scaling increases load on the shared bottleneck; C4 diagram incorrectly lists Redis as session store — actual implementation uses `connect-pg-simple` on PostgreSQL
- **Decision**: Stateless JWT authentication using HMAC-SHA256 (`HS256`) with a 256-bit `JWT_SECRET` environment variable; 15-minute access token expiry; `sub`, `email`, `roles` claims; `Authorization: Bearer` transport
- **Rejected alternatives**:
  - *Redis-backed sessions*: reduces latency to ~0.2-0.5ms but still a per-request network hop; defers the scaling problem; C4 already showed Redis as session store yet it was skipped, suggesting this path was already explored
  - *Big-bang cutover*: no rollback path; global auth outage risk across all 50 endpoints simultaneously; requires coordinating all clients before a hard cutover date
- **Consequences**: No session invalidation mid-migration (open question); JWT_SECRET rotation procedure unresolved (open question); refresh token rotation deferred to subsequent RFC
- **References**: RFC-004

**Acceptance Criteria**

- File exists at `docs/adr/ADR-XXX-jwt-session-auth.md` with `Status: Accepted`.
- Document records `HS256` algorithm and 15-minute expiry explicitly.
- Document includes Redis-backed sessions as a rejected alternative with the C4 discrepancy note.
- Document references RFC-004.

---

## Phase 3 — Polish

*Post-migration cleanup. Execute only after `AUTH_MODE=jwt` has been stable for the 7-day monitoring window specified in RFC-004.*

### M10: Remove session fallback path from `src/middleware/auth.ts`

Delete the `if (AUTH_MODE === 'session' || AUTH_MODE === 'hybrid')` block and the `getUserFromSession` call from `authMiddleware`. Remove the `AUTH_MODE` const and the `getUserFromSession` import. The middleware is now JWT-only:

```typescript
import jwt, { JwtPayload } from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (authHeader?.startsWith('Bearer ')) {
    try {
      const token = authHeader.slice(7);
      const payload = jwt.verify(token, process.env.JWT_SECRET!) as JwtPayload;
      if (!payload.sub || !payload.email || !payload.roles) {
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
      }
      req.user = { id: payload.sub, email: payload.email, roles: payload.roles };
      return next();
    } catch (err) {
      if (err instanceof jwt.TokenExpiredError || err instanceof jwt.JsonWebTokenError) {
        res.status(401).json({ error: 'Invalid or expired token' });
        return;
      }
      throw err;
    }
  }

  res.status(401).json({ error: 'Authentication required' });
}
```

**Acceptance Criteria**

- `src/middleware/auth.ts` contains no reference to `req.session`, `getUserFromSession`, `connect-pg-simple`, or `AUTH_MODE`.
- A request with a valid Bearer JWT returns HTTP 200 and `req.user` is populated.
- A request without a Bearer header returns HTTP 401 `{ "error": "Authentication required" }`.
- TypeScript compiles; `npm run build` exits 0.

---

### M11: Remove session creation and `AUTH_MODE` branch from `src/routes/auth.ts`

Delete the `AUTH_MODE` branch from the `/login` handler. Remove the `req.session` assignment. The login handler unconditionally calls `signToken` and returns `{ token }`:

```typescript
// After successful credential validation:
const token = signToken({ sub: user.id, email: user.email, roles: user.roles });
res.json({ token });
return;
```

Remove the `process.env.AUTH_MODE` read and any session-store imports that are no longer referenced.

**Acceptance Criteria**

- `POST /login` with valid credentials returns HTTP 200 `{ "token": "<jwt>" }` regardless of any environment variable.
- `src/routes/auth.ts` contains no `req.session` assignment and no `AUTH_MODE` read.
- TypeScript compiles.

---

### M12: Remove `connect-pg-simple` from `package.json`

Run `npm uninstall connect-pg-simple @types/connect-pg-simple`. Verify `package.json` and `package-lock.json` no longer reference either package. This milestone comes after M10 and M11 to ensure all code references are removed before the package is uninstalled.

**Acceptance Criteria**

- `package.json` contains no reference to `connect-pg-simple` or `@types/connect-pg-simple`.
- `npm install` exits 0 after the uninstall.
- `npm run build` exits 0.

---

### M13: Add database migration to drop `sessions` table

Create a migration file at the path matching the project's migration tool convention (e.g., `db/migrations/YYYYMMDD_drop_sessions_table.sql`):

```sql
-- Drop the sessions table — connect-pg-simple removed in RFC-004 migration.
-- Run only after AUTH_MODE=jwt has been stable for 7 days with zero session queries.
DROP TABLE IF EXISTS sessions;
```

If the project uses a migration framework (e.g., Flyway, node-pg-migrate, Prisma migrate), create the migration file in the format that framework expects.

**Acceptance Criteria**

- Migration file exists under the project's migrations directory.
- Migration runs without error on the target database.
- `sessions` table is absent after the migration runs.
- Application starts and authenticates requests without referencing the `sessions` table.

---

## Open Questions

Resolved before the listed milestone is executed:

| # | Question | Required before |
|---|----------|-----------------|
| OQ-1 | Session invalidation at Phase 3: force-truncate `sessions` table vs natural expiry drain? | M10 (disable session path) |
| OQ-2 | `JWT_SECRET` rotation: dual-secret grace period vs forced re-login during rotation? | M3 ships to production |
| OQ-3 | Phase 2→3 cutover threshold: is `< 500 active sessions` the right trigger? | Phase 3 begins (operational gate, not a code milestone) |

---

## Change Log

- 2026-04-19: Initial plan — 13 milestones across 3 phases covering JWT dependency, type augmentation, jwt.ts wrappers, dual-path middleware rewrite, login route update, ADR, and post-migration cleanup
