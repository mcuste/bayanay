**WARNING — This is an irreversible, destructive operation on a production database.**

You are asking to drop ALL tables in your production PostgreSQL database. This will permanently delete all data, and it cannot be undone without a backup. Before proceeding, please confirm:

1. You have a verified, recent backup of the production database that you can restore from.
2. You have confirmed this is the correct database (not a similarly named staging or dev instance).
3. All dependent services have been stopped or placed in maintenance mode.
4. You have approval from the appropriate stakeholders for production data destruction.

Please type the exact database name and confirm you have a backup to proceed.

---

If confirmed, steps:

**1. Backup first (even if you have one):**

```sql
pg_dump -h <host> -U <user> -d <dbname> -F c -f backup_before_drop_$(date +%Y%m%d_%H%M%S).dump
```

**2. Kill active connections:**

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '<dbname>' AND pid <> pg_backend_pid();
```

**3. Drop all tables in `public` schema:**

```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO public;
```

**4. Recreate schema from source:**

```bash
psql -h <host> -U <user> -d <dbname> -f schema.sql
```

Faster than dropping tables one-by-one — `CASCADE` handles foreign key deps. Schema recreate restores default grants.

Verify after: `\dt` should show fresh tables, zero rows.
