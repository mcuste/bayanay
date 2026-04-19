# PLAN-RFC-001: Replace PostgreSQL with MongoDB for User Profile Service

**RFC**: RFC-001
**Status**: Ready
**Created**: 2026-04-19
**Last Updated**: 2026-04-19

## File Structure Map

| File | Action | Responsibility |
|---|---|---|
| `services/user-profile/package.json` | Modify | Add `"mongodb": "^6.5.0"` to `dependencies` |
| `services/user-profile/src/config.ts` | Modify | Export `MONGODB_URI`, `MONGODB_DB_NAME`, `MIGRATION_PHASE` |
| `services/user-profile/src/db/mongo-client.ts` | Create | `MongoClient` singleton; `connect(): Promise<Db>` and `disconnect(): Promise<void>` |
| `services/user-profile/src/models/profile.ts` | Modify | Add `MongoProfile` interface + `profileToMongo()` and `mongoToProfile()` mapping functions |
| `services/user-profile/src/db/mongo-profile-repository.ts` | Create | `findByUserId(db, userId)` and `upsertProfile(db, profile)` against `user_profiles` collection |
| `services/user-profile/src/db/dual-write-profile-repository.ts` | Create | `getProfile` reads from PG; `updateProfile` writes PG first then MongoDB |
| `services/user-profile/src/db/shadow-read-profile-repository.ts` | Create | `getProfile` reads both stores in parallel, returns MongoDB result; `updateProfile` dual-writes |
| `services/user-profile/src/db/mongo-only-profile-repository.ts` | Create | `getProfile` and `updateProfile` talk to MongoDB only; no PG dependency |
| `services/user-profile/src/db/profile-repository.ts` | Modify | Factory selects active repository by `MIGRATION_PHASE` env var |
| `services/user-profile/src/server.ts` | Modify | Call `connect()` on startup; export `mongoDb: Db` for repository injection |
| `db/migrations/backfill-profiles-to-mongodb.ts` | Create | One-time script: reads all PG user profiles, writes to MongoDB via `upsertProfile` |
| `infra/mongodb/docker-compose.yml` | Create | MongoDB 7.x on port 27017 with named volume for local development |
| `db/migrations/drop-user-profile-pg-tables.sql` | Create | `DROP TABLE` for user profile PG tables; run after minimum 2-week burn-in with `MIGRATION_PHASE=mongo` |
| `docs/adr/ADR-XXX-mongodb-user-profiles.md` | Create | Record MongoDB decision, both rejected alternatives, phased migration strategy; references RFC-001 |

---

## Phase 1 — Core

*Walking skeleton: MongoDB client connects and the service can round-trip a document. `MIGRATION_PHASE` unset leaves existing PG behavior entirely unchanged. Dual-write, shadow-read, and mongo-only modes compile and are selectable via env var but are not deployed until each RFC migration phase begins.*

### M1: Add `mongodb@^6.5.0` to `services/user-profile/package.json`

In `services/user-profile/package.json`, add `"mongodb": "^6.5.0"` to `dependencies`. Run `npm install` to update the lockfile.

**Acceptance Criteria**

- `npm install` exits 0.
- `import { MongoClient } from 'mongodb'` in any TypeScript file under `services/user-profile/` compiles without errors.

---

### M2: Add MongoDB config exports to `services/user-profile/src/config.ts`

In `services/user-profile/src/config.ts`, append three exports after the existing PostgreSQL config block:

```typescript
export const MONGODB_URI = process.env.MONGODB_URI ?? 'mongodb://localhost:27017';
export const MONGODB_DB_NAME = process.env.MONGODB_DB_NAME ?? 'user-profiles';
export const MIGRATION_PHASE = process.env.MIGRATION_PHASE ?? '';
// Valid MIGRATION_PHASE values: '' (PG-only), 'dual-write', 'shadow-read', 'mongo'
```

**Acceptance Criteria**

- TypeScript compiles after the change.
- `MONGODB_URI`, `MONGODB_DB_NAME`, and `MIGRATION_PHASE` are importable from `../config`.
- All existing exports in `config.ts` are unchanged.

---

### M3: Create `src/db/mongo-client.ts` — `MongoClient` singleton

Create `services/user-profile/src/db/mongo-client.ts`:

```typescript
import { MongoClient, Db } from 'mongodb';
import { MONGODB_URI, MONGODB_DB_NAME } from '../config';

let client: MongoClient | null = null;

export async function connect(): Promise<Db> {
  client = new MongoClient(MONGODB_URI);
  await client.connect();
  return client.db(MONGODB_DB_NAME);
}

export async function disconnect(): Promise<void> {
  await client?.close();
  client = null;
}
```

No retry logic and no timeout options — happy path only. Connection options are added in M16.

**Acceptance Criteria**

- Module compiles; `import { connect, disconnect } from './db/mongo-client'` resolves without errors.
- `connect()` called against a reachable MongoDB returns a `Db` instance.
- `disconnect()` called after `connect()` does not throw.

---

### M4: Add `MongoProfile` type and mapping functions to `src/models/profile.ts`

In `services/user-profile/src/models/profile.ts`, add after the existing `Profile` interface:

```typescript
export interface MongoProfile {
  _id: string;
  userId: string;
  preferences: {
    language: string;
    timezone: string;
    theme: string;
  };
  notifications: {
    email: { enabled: boolean; digest: string };
    push: { enabled: boolean };
  };
  uiCustomization: {
    sidebar: string;
    density: string;
    pinnedViews: string[];
  };
  updatedAt: string;
}

export function profileToMongo(userId: string, profile: Profile): MongoProfile {
  return {
    _id: userId,
    userId,
    preferences: profile.preferences,
    notifications: profile.notifications,
    uiCustomization: profile.uiCustomization,
    updatedAt: profile.updatedAt,
  };
}

export function mongoToProfile(doc: MongoProfile): Profile {
  return {
    userId: doc.userId,
    preferences: doc.preferences,
    notifications: doc.notifications,
    uiCustomization: doc.uiCustomization,
    updatedAt: doc.updatedAt,
  };
}
```

**Acceptance Criteria**

- TypeScript compiles after the change.
- Existing `Profile` type is unchanged.
- `mongoToProfile(profileToMongo(userId, profile))` produces an object whose fields equal `{ ...profile, userId }`.
- `profileToMongo` sets `_id` and `userId` to the same value.

---

### M5: Create `src/db/mongo-profile-repository.ts` — `findByUserId` and `upsertProfile`

Create `services/user-profile/src/db/mongo-profile-repository.ts`:

```typescript
import { Db } from 'mongodb';
import { MongoProfile } from '../models/profile';

const COLLECTION = 'user_profiles';

export async function findByUserId(db: Db, userId: string): Promise<MongoProfile | null> {
  const doc = await db.collection<MongoProfile>(COLLECTION).findOne({ userId });
  return doc as MongoProfile | null;
}

export async function upsertProfile(db: Db, profile: MongoProfile): Promise<void> {
  await db.collection<MongoProfile>(COLLECTION).replaceOne(
    { userId: profile.userId },
    profile,
    { upsert: true },
  );
}
```

No error handling — happy path only.

**Acceptance Criteria**

- Module compiles; `import { findByUserId, upsertProfile } from './db/mongo-profile-repository'` resolves without errors.
- `upsertProfile(db, doc)` inserts a document when no document with `userId` exists.
- Calling `upsertProfile(db, doc)` a second time with the same `userId` replaces the document (no duplicate).
- `findByUserId(db, doc.userId)` returns the document after `upsertProfile`.
- `findByUserId(db, 'nonexistent-id')` returns `null`.

---

### M6: Wire `connect()` into `services/user-profile/src/server.ts` startup

In `services/user-profile/src/server.ts`, import `connect` from `./db/mongo-client` and export the returned `Db`. Call `connect()` in the startup sequence before `app.listen()`:

```typescript
import { connect } from './db/mongo-client';
import { Db } from 'mongodb';

export let mongoDb: Db | null = null;

// Inside the async startup function, before app.listen():
mongoDb = await connect();
```

When `MIGRATION_PHASE` is `''` (default), `mongoDb` is connected but unused — the PG repository remains active (see M8).

**Acceptance Criteria**

- Server starts without error when `MONGODB_URI` is reachable.
- `mongoDb` is a non-null `Db` instance after startup.
- TypeScript compiles; `npm run build` exits 0.
- All existing API endpoints continue to work via the PG repository — `MIGRATION_PHASE` unset.

---

### M7: Create `src/db/dual-write-profile-repository.ts`

Create `services/user-profile/src/db/dual-write-profile-repository.ts`:

```typescript
import { Db } from 'mongodb';
import { Profile, profileToMongo } from '../models/profile';
import { getProfile as pgGetProfile, updateProfile as pgUpdateProfile } from './postgres-profile-repository';
import { upsertProfile } from './mongo-profile-repository';

export class DualWriteProfileRepository {
  constructor(private readonly db: Db) {}

  async getProfile(userId: string): Promise<Profile | null> {
    return pgGetProfile(userId);
  }

  async updateProfile(userId: string, data: Partial<Profile>): Promise<void> {
    await pgUpdateProfile(userId, data);
    const updated = await pgGetProfile(userId);
    if (updated) {
      await upsertProfile(this.db, profileToMongo(userId, updated));
    }
  }
}
```

`updateProfile` writes PG first; if `pgUpdateProfile` throws, `upsertProfile` is never called. MongoDB write failures are silently propagated in Phase 1 — error handling added in M15.

**Acceptance Criteria**

- `getProfile(userId)` delegates to the PG repository and returns its result unchanged.
- `updateProfile(userId, data)` calls `pgUpdateProfile` before `upsertProfile` — if `pgUpdateProfile` throws, `upsertProfile` is not called.
- TypeScript compiles; no unresolved imports.

---

### M8: Add `dual-write` case to `src/db/profile-repository.ts`

In `services/user-profile/src/db/profile-repository.ts`, replace the direct PG repository export with a factory that reads `MIGRATION_PHASE` from config:

```typescript
import { MIGRATION_PHASE } from '../config';
import { mongoDb } from '../server';
import { DualWriteProfileRepository } from './dual-write-profile-repository';

function makeRepository() {
  if (MIGRATION_PHASE === 'dual-write') {
    return new DualWriteProfileRepository(mongoDb!);
  }
  return pgProfileRepository; // existing PG instance
}

export const profileRepository = makeRepository();
```

Adjust the existing PG repository variable name to match the current file's export.

**Acceptance Criteria**

- With `MIGRATION_PHASE` unset or `''`: `profileRepository` is the existing PG repository — no behavior change, all existing tests pass.
- With `MIGRATION_PHASE=dual-write`: `profileRepository` is a `DualWriteProfileRepository` instance.
- TypeScript compiles; `npm run build` exits 0.

---

### M9: Create `src/db/shadow-read-profile-repository.ts`

Create `services/user-profile/src/db/shadow-read-profile-repository.ts`:

```typescript
import { Db } from 'mongodb';
import { Profile, mongoToProfile, profileToMongo } from '../models/profile';
import { getProfile as pgGetProfile, updateProfile as pgUpdateProfile } from './postgres-profile-repository';
import { findByUserId, upsertProfile } from './mongo-profile-repository';

export class ShadowReadProfileRepository {
  constructor(private readonly db: Db) {}

  async getProfile(userId: string): Promise<Profile | null> {
    const [mongoDoc, pgProfile] = await Promise.all([
      findByUserId(this.db, userId),
      pgGetProfile(userId),
    ]);
    // Field-level divergence logging is added in M17
    return mongoDoc ? mongoToProfile(mongoDoc) : pgProfile;
  }

  async updateProfile(userId: string, data: Partial<Profile>): Promise<void> {
    await pgUpdateProfile(userId, data);
    const updated = await pgGetProfile(userId);
    if (updated) {
      await upsertProfile(this.db, profileToMongo(userId, updated));
    }
  }
}
```

Reads from both stores in parallel; returns the MongoDB result when present. PG result is retained for comparison (logging added in M17). Write path is identical to `DualWriteProfileRepository`.

**Acceptance Criteria**

- `getProfile(userId)` when MongoDB has the document: returns the MongoDB document converted via `mongoToProfile`, not the PG document.
- `getProfile(userId)` when MongoDB has no document: falls back to and returns the PG result.
- `updateProfile` calls `pgUpdateProfile` first, then `upsertProfile` — same ordering as `DualWriteProfileRepository`.
- TypeScript compiles.

---

### M10: Create `src/db/mongo-only-profile-repository.ts`

Create `services/user-profile/src/db/mongo-only-profile-repository.ts`:

```typescript
import { Db } from 'mongodb';
import { Profile, MongoProfile, mongoToProfile, profileToMongo } from '../models/profile';
import { findByUserId, upsertProfile } from './mongo-profile-repository';

export class MongoOnlyProfileRepository {
  constructor(private readonly db: Db) {}

  async getProfile(userId: string): Promise<Profile | null> {
    const doc = await findByUserId(this.db, userId);
    return doc ? mongoToProfile(doc) : null;
  }

  async updateProfile(userId: string, data: Partial<Profile>): Promise<void> {
    const existing = await findByUserId(this.db, userId);
    if (!existing) return;
    const merged: MongoProfile = {
      ...existing,
      ...data,
      userId,
      updatedAt: new Date().toISOString(),
    };
    await upsertProfile(this.db, merged);
  }
}
```

`updateProfile` uses a read-modify-write pattern — happy path only. The pattern is replaced with an atomic `$set` in M18.

**Acceptance Criteria**

- `getProfile(userId)` returns `null` when no document exists in MongoDB.
- `getProfile(userId)` returns a `Profile` shaped object (no `_id` field) when the document exists.
- `updateProfile(userId, { preferences: { theme: 'light' } })` merges the partial data — the stored document retains all fields not present in `data` while updating those that are.
- TypeScript compiles; no PG imports are present in this file.

---

### M11: Add `shadow-read` and `mongo` cases to `src/db/profile-repository.ts`

In `services/user-profile/src/db/profile-repository.ts`, extend the factory from M8 with two additional cases:

```typescript
import { ShadowReadProfileRepository } from './shadow-read-profile-repository';
import { MongoOnlyProfileRepository } from './mongo-only-profile-repository';

function makeRepository() {
  switch (MIGRATION_PHASE) {
    case 'dual-write':
      return new DualWriteProfileRepository(mongoDb!);
    case 'shadow-read':
      return new ShadowReadProfileRepository(mongoDb!);
    case 'mongo':
      return new MongoOnlyProfileRepository(mongoDb!);
    default:
      return pgProfileRepository;
  }
}

export const profileRepository = makeRepository();
```

**Acceptance Criteria**

- With `MIGRATION_PHASE=shadow-read`: `profileRepository` is a `ShadowReadProfileRepository` instance.
- With `MIGRATION_PHASE=mongo`: `profileRepository` is a `MongoOnlyProfileRepository` instance.
- With `MIGRATION_PHASE` unset: `profileRepository` is the PG repository — unchanged from pre-RFC behavior.
- TypeScript compiles; `npm run build` exits 0.

---

## Phase 2 — Details

### M12: Create `db/migrations/backfill-profiles-to-mongodb.ts` — main backfill loop

Create `db/migrations/backfill-profiles-to-mongodb.ts`. This script is run once during RFC migration Phase 3 (after dual-write is stable). It reads all rows from the PostgreSQL user profile tables, converts each to `MongoProfile`, and writes to MongoDB via `upsertProfile`. The `--dry-run` flag is added in M13.

```typescript
import { Pool } from 'pg';
import { connect, disconnect } from '../../services/user-profile/src/db/mongo-client';
import { upsertProfile } from '../../services/user-profile/src/db/mongo-profile-repository';
import { profileToMongo } from '../../services/user-profile/src/models/profile';

async function run(): Promise<void> {
  const pg = new Pool({ connectionString: process.env.POSTGRES_URL });
  const db = await connect();

  const { rows } = await pg.query<{
    user_id: string;
    preferences: Record<string, unknown>;
    notification_settings: Record<string, unknown>;
    ui_customization: Record<string, unknown>;
    updated_at: string;
  }>('SELECT user_id, preferences, notification_settings, ui_customization, updated_at FROM user_profiles');

  let processed = 0;
  for (const row of rows) {
    const profile = {
      userId: row.user_id,
      preferences: row.preferences as any,
      notifications: row.notification_settings as any,
      uiCustomization: row.ui_customization as any,
      updatedAt: row.updated_at,
    };
    await upsertProfile(db, profileToMongo(row.user_id, profile));
    processed++;
  }

  console.log(`Backfill complete: ${processed} profiles written to MongoDB`);
  await pg.end();
  await disconnect();
}

run().catch((err) => { console.error(err); process.exit(1); });
```

**Acceptance Criteria**

- Script exits 0 when run against a populated PG database and a reachable MongoDB.
- Each `user_id` present in PG appears as a document in the MongoDB `user_profiles` collection after the script runs.
- The document count in MongoDB `user_profiles` equals the row count in the PG `user_profiles` table.

---

### M13: Add `--dry-run` flag to `db/migrations/backfill-profiles-to-mongodb.ts`

In `db/migrations/backfill-profiles-to-mongodb.ts`, parse `process.argv` for `--dry-run`. When present, log each profile that would be written but do not call `upsertProfile`:

```typescript
const DRY_RUN = process.argv.includes('--dry-run');

// Inside the loop:
if (DRY_RUN) {
  console.log(`[dry-run] would upsert userId=${row.user_id}`);
} else {
  await upsertProfile(db, profileToMongo(row.user_id, profile));
}
processed++;
```

Also update the completion log line:

```typescript
console.log(`Backfill complete (${DRY_RUN ? 'DRY RUN' : 'LIVE'}): ${processed} profiles ${DRY_RUN ? 'inspected' : 'written'}`);
```

**Acceptance Criteria**

- `ts-node db/migrations/backfill-profiles-to-mongodb.ts --dry-run` exits 0 and logs one line per PG row without inserting any documents into MongoDB.
- `ts-node db/migrations/backfill-profiles-to-mongodb.ts` (no flag) writes documents to MongoDB as in M12.
- MongoDB `user_profiles` collection document count is 0 after a `--dry-run` run against an empty MongoDB.

---

### M14: Create a unique index on `userId` in `mongo-client.ts` `connect()`

In `services/user-profile/src/db/mongo-client.ts`, after `client.connect()` and before the function returns, ensure the `userId` unique index exists on the `user_profiles` collection:

```typescript
const db = client.db(MONGODB_DB_NAME);
await db.collection('user_profiles').createIndex(
  { userId: 1 },
  { unique: true, background: true },
);
return db;
```

`createIndex` is idempotent — calling it on an already-indexed collection is a no-op.

**Acceptance Criteria**

- `connect()` succeeds on a fresh MongoDB instance and creates the index.
- After `connect()`, `db.collection('user_profiles').indexInformation()` includes an index with key `{ userId: 1 }` marked unique.
- `connect()` succeeds when the index already exists (idempotent).

---

### M15: Add MongoDB write failure handling to `DualWriteProfileRepository`

In `services/user-profile/src/db/dual-write-profile-repository.ts`, wrap the `upsertProfile` call in `updateProfile` with a `try/catch`. Log failures; do not rethrow:

```typescript
import { logger } from '../logger'; // use the existing project logger

async updateProfile(userId: string, data: Partial<Profile>): Promise<void> {
  await pgUpdateProfile(userId, data);
  const updated = await pgGetProfile(userId);
  if (updated) {
    try {
      await upsertProfile(this.db, profileToMongo(userId, updated));
    } catch (err) {
      logger.error({ err, userId }, 'dual-write: MongoDB upsert failed — PG is authoritative');
    }
  }
}
```

Adjust the `logger` import to match the project's existing logger module path and call signature.

**Acceptance Criteria**

- When `upsertProfile` throws, `updateProfile` resolves without rethrowing — the caller receives a resolved promise.
- When `upsertProfile` throws, the error is logged with `userId` and the error object.
- When `upsertProfile` succeeds, no error is logged and `updateProfile` resolves normally.

---

### M16: Add connection timeout options to `src/db/mongo-client.ts`

In `services/user-profile/src/db/mongo-client.ts`, pass `MongoClientOptions` to the `MongoClient` constructor:

```typescript
client = new MongoClient(MONGODB_URI, {
  serverSelectionTimeoutMS: 5_000,
  connectTimeoutMS: 10_000,
  socketTimeoutMS: 30_000,
});
```

If `connect()` fails, let the error propagate to `server.ts` — the process should fail fast at startup rather than start in a degraded state.

**Acceptance Criteria**

- Server startup fails with a thrown error when MongoDB is unreachable and `MIGRATION_PHASE` requires it (e.g., `dual-write`).
- When MongoDB is reachable, `connect()` returns a `Db` instance within 5 seconds of a connection attempt.
- With `MIGRATION_PHASE=''` (PG-only), startup proceeds even if `connect()` would fail — MongoDB connection is best-effort only in PG mode. (Adjust `server.ts` to conditionally skip `connect()` if `MIGRATION_PHASE === ''`.)

---

### M17: Add field-level divergence logging to `ShadowReadProfileRepository`

In `services/user-profile/src/db/shadow-read-profile-repository.ts`, after the `Promise.all` resolves, compare non-null MongoDB and PG profiles field by field and log each mismatch:

```typescript
import { logger } from '../logger';

async getProfile(userId: string): Promise<Profile | null> {
  const [mongoDoc, pgProfile] = await Promise.all([
    findByUserId(this.db, userId),
    pgGetProfile(userId),
  ]);

  if (mongoDoc && pgProfile) {
    const mongo = mongoToProfile(mongoDoc);
    const fields = ['preferences', 'notifications', 'uiCustomization'] as const;
    for (const field of fields) {
      if (JSON.stringify(mongo[field]) !== JSON.stringify(pgProfile[field])) {
        logger.warn(
          { userId, field, mongoValue: mongo[field], pgValue: pgProfile[field] },
          'shadow-read: field divergence detected',
        );
      }
    }
  }

  return mongoDoc ? mongoToProfile(mongoDoc) : pgProfile;
}
```

**Acceptance Criteria**

- When MongoDB and PG profiles are identical for a given `userId`: no divergence log lines are emitted.
- When `preferences` differ: exactly one `warn` log line is emitted with `field: 'preferences'`, `userId`, `mongoValue`, and `pgValue`.
- When `notifications` and `uiCustomization` both differ: two `warn` log lines are emitted, one per differing field.
- The returned profile is the MongoDB result in all cases when the document exists.

---

### M18: Replace read-modify-write in `MongoOnlyProfileRepository.updateProfile` with atomic `$set`

In `services/user-profile/src/db/mongo-only-profile-repository.ts`, replace the `findByUserId + upsertProfile` pattern in `updateProfile` with a `$set` update that modifies only the supplied fields atomically:

```typescript
import { Db, UpdateFilter } from 'mongodb';
import { MongoProfile, Profile } from '../models/profile';

async updateProfile(userId: string, data: Partial<Profile>): Promise<void> {
  const setFields: UpdateFilter<MongoProfile>['$set'] = {
    updatedAt: new Date().toISOString(),
  };
  if (data.preferences !== undefined) setFields['preferences'] = data.preferences;
  if (data.notifications !== undefined) setFields['notifications'] = data.notifications;
  if (data.uiCustomization !== undefined) setFields['uiCustomization'] = data.uiCustomization;

  await this.db.collection<MongoProfile>('user_profiles').updateOne(
    { userId },
    { $set: setFields },
  );
}
```

Remove the `findByUserId` import if no longer needed in this file.

**Acceptance Criteria**

- `updateProfile(userId, { preferences: { theme: 'light', language: 'en', timezone: 'UTC' } })` modifies only the `preferences` field — `notifications` and `uiCustomization` are unchanged in the stored document.
- `updatedAt` is always updated to the current ISO timestamp.
- No intermediate `findByUserId` call is made — the update is a single MongoDB operation.
- TypeScript compiles after removing the unused `findByUserId` import.

---

### M19: Create `docs/adr/ADR-XXX-mongodb-user-profiles.md`

Create the ADR using the `software:adr` skill. It must record:

- **Status**: Accepted
- **Context**: User profile service stores preferences, notification settings, and UI customization in PostgreSQL JSONB columns lacking GIN indexes; JSONB predicate pushdown and partial reads are expensive; profile data is document-shaped; the relational model introduces impedance mismatch and maintenance burden; half the profile fields already live in untyped JSONB
- **Decision**: Replace PostgreSQL with MongoDB for the user profile service; store profiles as native documents in the `user_profiles` collection; migrate via a phased dual-write migration with rollback capability at each phase; use MongoDB Atlas for managed operations (resolves RFC-001 open question on operational expertise)
- **Rejected alternatives**:
  - *Optimize PostgreSQL JSONB with GIN indexes*: addresses query performance but not the structural mismatch; profile complexity will grow; impedance mismatch resurfaces at each new field; working within relational constraints for inherently document-shaped data
  - *Hybrid — PostgreSQL for identity + MongoDB for profiles*: two operational datastores for a single service domain; cross-store lookups require application-layer joins; distributed state consistency risk (profile in Mongo, user deleted from PG); doubles backup strategies and failure modes without meaningful benefit
- **Consequences**: No multi-document transactions required (single user profile = single document); MongoDB schema validation deferred to application layer initially (JSON Schema validator can be added post-migration); rollback trigger criteria (error rate threshold, latency SLO breach, or manual decision) to be documented in the migration runbook before cutover
- **References**: RFC-001

**Acceptance Criteria**

- File exists at `docs/adr/ADR-XXX-mongodb-user-profiles.md` with `Status: Accepted`.
- Document records `user_profiles` as the MongoDB collection name.
- Document includes both rejected alternatives (GIN indexes and Hybrid) with their rejection reasons.
- Document references RFC-001.

---

## Phase 3 — Polish

*Post-cutover cleanup. Execute only after `MIGRATION_PHASE=mongo` has been stable for the minimum 2-week burn-in period specified in RFC-001.*

### M20: Create `infra/mongodb/docker-compose.yml` for local development

Create `infra/mongodb/docker-compose.yml`:

```yaml
services:
  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    environment:
      MONGO_INITDB_DATABASE: user-profiles

volumes:
  mongodb_data:
```

**Acceptance Criteria**

- `docker compose -f infra/mongodb/docker-compose.yml up -d` exits 0.
- MongoDB is reachable at `mongodb://localhost:27017` after container starts.
- Data persists across container restarts via the named `mongodb_data` volume.

---

### M21: Create `db/migrations/drop-user-profile-pg-tables.sql`

Create `db/migrations/drop-user-profile-pg-tables.sql`:

```sql
-- Drop user profile tables from PostgreSQL.
-- RFC-001: PostgreSQL replaced by MongoDB for user profile service.
-- PREREQUISITE: MIGRATION_PHASE=mongo must have been stable for a minimum of 2 weeks
-- with zero observed PG queries for the user_profiles table.
-- Run this migration ONLY after confirming no application code reads or writes these tables.
DROP TABLE IF EXISTS user_profiles;
```

If the project uses a migration tool (e.g., Flyway, node-pg-migrate), create the file in that tool's expected format instead.

**Acceptance Criteria**

- Migration file exists under the project's migrations directory.
- Running the migration drops the `user_profiles` table without error.
- Application started with `MIGRATION_PHASE=mongo` handles profile reads and writes without referencing the dropped table.

---

### M22: Simplify `src/db/profile-repository.ts` to export `MongoOnlyProfileRepository` directly

In `services/user-profile/src/db/profile-repository.ts`, remove the `MIGRATION_PHASE` switch and all imports of `DualWriteProfileRepository`, `ShadowReadProfileRepository`, and the PG repository. Export the Mongo-only repository directly:

```typescript
import { MongoOnlyProfileRepository } from './mongo-only-profile-repository';
import { mongoDb } from '../server';

export const profileRepository = new MongoOnlyProfileRepository(mongoDb!);
```

**Acceptance Criteria**

- `src/db/profile-repository.ts` contains no reference to `MIGRATION_PHASE`, `DualWriteProfileRepository`, `ShadowReadProfileRepository`, or `pgProfileRepository`.
- All profile service API endpoints continue to serve requests correctly via MongoDB.
- TypeScript compiles; `npm run build` exits 0.

---

### M23: Delete migration-era repository files

Delete the following files, which are no longer imported after M22:

- `services/user-profile/src/db/dual-write-profile-repository.ts`
- `services/user-profile/src/db/shadow-read-profile-repository.ts`
- `services/user-profile/src/db/postgres-profile-repository.ts`

Verify no file in `services/user-profile/src/` imports from these paths before deleting.

**Acceptance Criteria**

- The three files no longer exist in the repository.
- TypeScript compilation produces zero errors after deletion; `npm run build` exits 0.
- No file in `services/user-profile/src/` imports from `dual-write-profile-repository`, `shadow-read-profile-repository`, or `postgres-profile-repository`.

---

## RFC Goal Coverage

| RFC Goal | Milestone(s) |
|---|---|
| Replace PostgreSQL with MongoDB as the data layer | M3, M5, M6, M8, M11 (all migration phases implemented); M22, M23 (PG removed) |
| Store profile data as native MongoDB documents with nested fields | M4 (`MongoProfile` type), M5 (`user_profiles` collection) |
| Migrate existing profile data with zero data loss | M12 (backfill loop), M13 (`--dry-run` verification) |
| Maintain existing user profile API contract | M4 (`mongoToProfile` mapping), M9/M10 (all repos return `Profile`-shaped data) |
| Validated migration runbook with rollback at each phase | M8, M11 (`MIGRATION_PHASE` env var gates each phase; revert by changing env var) |
| ADR for MongoDB decision | M19 |

---

## Open Questions

Resolved before the listed milestone is executed:

| # | Question | Required before |
|---|----------|-----------------|
| OQ-1 | Acceptable downtime window for cutover (Phase 5 shadow → mongo flip): is a rolling restart acceptable, or is a maintenance window required? | M11 deployed to production with `MIGRATION_PHASE=shadow-read` |
| OQ-2 | Rollback trigger criteria: error rate threshold, latency SLO breach, or manual tech-lead decision? Criteria must be documented in the migration runbook. | M11 deployed to production |
| OQ-3 | MongoDB schema validation: enforce JSON Schema validator at database level or application layer only? | M21 (drop PG tables, at which point schema control moves entirely to MongoDB) |

---

## Change Log

- 2026-04-19: Initial plan — 23 milestones across 3 phases covering MongoDB client, type mapping, four repository implementations (PG-only, dual-write, shadow-read, mongo-only), backfill script, connection hardening, divergence logging, ADR, and post-migration decommission
