---
origin: "prisma/skills"
origin_skill: "prisma-cli"
origin_version: "7.0.0"
forked_date: "2026-03-02"
sections_kept: "migrate command family (migrate dev, migrate deploy, migrate reset, migrate status, migrate diff), db push vs migrate distinction, Prisma v7 config changes, Bun runtime note"
sections_removed: "prisma init, prisma generate, prisma dev (local Postgres), prisma db pull/seed/execute, prisma studio, prisma validate/format/debug — reference material not needed for migrate-focused slice"
---

# Prisma CLI — Migrate Commands (v7)

The `migrate` command family and `db push` vs `migrate` distinction. Agents commonly confuse these.

> See also: `prisma-database-setup.md` for initial connection setup. `prisma-upgrade-v7.md` for complete v6→v7 migration (including removed CLI flags in full context).

## db push vs migrate — Key Distinction

| | `db push` | `migrate dev` |
|--|-----------|---------------|
| **Creates migration files** | No | Yes |
| **Migration history** | No | Yes |
| **For production** | No | Yes (via `migrate deploy`) |
| **Schema drift detection** | No | Yes |
| **When to use** | Prototyping, development | All production workflows |

**Rule:** Use `db push` only during initial schema exploration. Switch to `migrate dev` once the schema stabilizes.

## prisma migrate dev (Development)

Creates a migration file and applies it to the dev database.

```bash
# Create and apply migration
prisma migrate dev

# Create migration with descriptive name
prisma migrate dev --name add_users_table
prisma migrate dev --name add_email_index

# Create migration file only (don't apply yet)
prisma migrate dev --create-only
```

**What it does:**
1. Detects schema changes since last migration
2. Generates a SQL migration file in `prisma/migrations/`
3. Applies the migration to the development database
4. Regenerates Prisma Client

**v7 change:** `--skip-generate` removed. Run `prisma generate` explicitly if needed.

## prisma migrate deploy (Production/CI)

Applies all pending migrations. **Only for production/staging environments.**

```bash
# In CI/CD pipeline
prisma migrate deploy
```

**What it does:**
- Checks which migrations haven't been applied
- Applies them in order
- Never creates new migration files
- Fails if migration history has drift

**Do NOT run `migrate dev` in production** — it drops data during reset and creates new migration files.

## prisma migrate reset

Resets the database by dropping all data and re-applying all migrations.

```bash
# Reset dev database (destructive!)
prisma migrate reset

# Skip confirmation prompt
prisma migrate reset --force

# Skip seed after reset
# (v7 removed --skip-seed flag — configure seed in prisma.config.ts instead)
```

**v7 change:** `--skip-seed` removed. Control seeding in `prisma.config.ts`:
```typescript
migrations: {
  seed: 'tsx prisma/seed.ts',  // Remove this line to skip seeding
}
```

## prisma migrate status

Check which migrations have been applied.

```bash
prisma migrate status
```

Output:
- Lists all migration files
- Marks each as `Applied` or `Pending`
- Reports database drift if schema changed outside migrations

## prisma migrate diff

Generate a SQL diff between two schema states (useful for review).

```bash
# Diff current schema against deployed database
prisma migrate diff \
  --from-config-datasource \
  --to-schema-datamodel prisma/schema.prisma \
  --script

# Diff two schema files
prisma migrate diff \
  --from-schema-datamodel old-schema.prisma \
  --to-schema-datamodel new-schema.prisma \
  --script
```

## Prisma v7 Configuration Changes

Environment variables are no longer auto-loaded. Add to `prisma.config.ts`:

```typescript
import 'dotenv/config'
import { defineConfig, env } from 'prisma/config'

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  datasource: {
    url: env('DATABASE_URL'),
  },
})
```

## Bun Runtime

Always use `--bun` flag when running with Bun:
```bash
bunx --bun prisma migrate dev --name add_users
bunx --bun prisma migrate deploy
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running `migrate dev` in production | Use `migrate deploy` in CI/CD |
| Using `db push` for production schema | Use `migrate dev` to track migrations |
| Forgetting to commit migration files | Always commit `prisma/migrations/` to git |
| Running `migrate reset` on production | Never — it drops all data |
| Not naming migrations descriptively | `--name` flag makes history readable |
