# prisma-patterns — Debugging Reference

## Common Debugging Scenarios

### N+1 query explosion

**Symptom:** API response times degrade linearly with result count. A list endpoint that returns 50 records takes 2-3 seconds. Database connection pool exhausts under moderate load.

**Root cause:** Fetching a list of records and then issuing a separate query per record to load a relation — either through explicit loops or through lazy-loading patterns that hide the per-record query.

**Diagnosis:**

- Enable query logging to count queries per request:
  ```typescript
  const prisma = new PrismaClient({
    log: [{ emit: 'event', level: 'query' }],
  });

  let queryCount = 0;
  prisma.$on('query', (e) => {
    queryCount++;
    console.log(`Query #${queryCount} (${e.duration}ms): ${e.query}`);
  });
  ```
- If `queryCount` scales with the number of parent records (e.g., 1 list query + N relation queries), it's N+1
- Check the service code for patterns like `records.map(r => prisma.related.findMany({ where: { parentId: r.id } }))` — this is explicit N+1
- Check for missing `include` or `select` on the parent query — if relations are accessed after the query returns, each access triggers a lazy load

**Fix pattern:**

- Use `include` to eagerly load relations in the parent query: `prisma.user.findMany({ include: { posts: true } })`
- Use `select` with nested `select` for partial relation loading (avoids fetching unused columns): `prisma.user.findMany({ select: { id: true, posts: { select: { title: true } } } })`
- For complex aggregations that don't map to `include`, use `prisma.$queryRaw` with a JOIN and process results in application code
- For paginated relations, use Prisma's nested `take`/`skip`: `include: { posts: { take: 10, orderBy: { createdAt: 'desc' } } }`

### Migration drift

**Symptom:** `prisma migrate deploy` fails with `Migration has already been applied but is missing from the migrations directory`. Schema changes work locally but break in staging/CI. Team members get different migration states.

**Root cause:** The `_prisma_migrations` table in the database records applied migrations, but the local `prisma/migrations/` directory is out of sync — usually from rebasing over someone else's migration, deleting a migration file, or running `migrate dev` against a shared database.

**Diagnosis:**

- Compare local migrations to database state:
  ```bash
  npx prisma migrate diff \
    --from-migrations ./prisma/migrations \
    --to-schema-datamodel ./prisma/schema.prisma
  ```
- Check the `_prisma_migrations` table directly for applied migrations:
  ```sql
  SELECT migration_name, finished_at, rolled_back_at
  FROM _prisma_migrations
  ORDER BY started_at;
  ```
- Compare the migration names in the database with the directories under `prisma/migrations/` — look for entries present in one but not the other
- Run `npx prisma migrate status` — it reports pending, failed, and missing migrations

**Fix pattern:**

- For dev databases: `npx prisma migrate reset` — drops and recreates the database from the migration history (destructive, dev only)
- For shared databases with a single missing migration: manually insert the migration record into `_prisma_migrations` if the schema change was already applied by other means
- For drift between team members: ensure `prisma/migrations/` is committed to git, never gitignored. Treat migration files as immutable once pushed
- For CI: run `prisma migrate deploy` (not `migrate dev`) — it applies pending migrations without generating new ones

### Prisma Client stale after schema change

**Symptom:** TypeScript shows old field names or missing new fields after editing `schema.prisma`. Autocomplete suggests the previous schema. Runtime errors like `Unknown field 'newColumn' for model 'User'`.

**Root cause:** The generated Prisma Client in `node_modules/.prisma/client/` hasn't been regenerated after the schema change. The TypeScript language server caches the old generated types.

**Diagnosis:**

- Check when the client was last generated:
  ```bash
  stat node_modules/.prisma/client/index.js | grep Modify
  ```
  Compare this timestamp to the last `schema.prisma` edit — if the schema is newer, the client is stale
- Check if `prisma generate` is missing from the `postinstall` script in `package.json`
- Verify the `output` path in the `generator` block of `schema.prisma` — a custom output path means the client is generated somewhere other than the default location

**Fix pattern:**

- Run `npx prisma generate` after every schema change — this regenerates the client
- Add `"postinstall": "prisma generate"` to `package.json` scripts so `npm install` / `pnpm install` keeps the client in sync
- Restart the TypeScript language server after regeneration (VS Code: Cmd+Shift+P > "TypeScript: Restart TS Server")
- If using a monorepo, ensure `prisma generate` runs in the package that owns the schema, not at the root

### Transaction timeout

**Symptom:** `Transaction already closed: A batch query cannot be executed on a closed transaction`. Operations succeed individually but fail when wrapped in `$transaction`. Intermittent failures under load.

**Root cause:** The interactive transaction exceeds the default 5-second timeout. This happens when the transaction includes slow queries, external API calls, or awaits that take too long. The connection is released and the transaction is rolled back.

**Diagnosis:**

- Measure the actual transaction duration:
  ```typescript
  const start = performance.now();
  try {
    await prisma.$transaction(async (tx) => {
      // ... operations
      console.log(`Tx duration: ${performance.now() - start}ms`);
    });
  } catch (e) {
    console.log(`Tx failed after: ${performance.now() - start}ms`);
    throw e;
  }
  ```
- Check if the transaction contains any `await` calls to external services (HTTP requests, queue publishes) — these should not be inside a transaction
- Enable query logging and check for slow individual queries within the transaction:
  ```typescript
  prisma.$on('query', (e) => {
    if (e.duration > 100) console.warn(`Slow query (${e.duration}ms): ${e.query}`);
  });
  ```
- Check the connection pool size (`connection_limit` in the database URL) — under load, transactions may wait for a connection before even starting

**Fix pattern:**

- Increase the timeout for legitimately long transactions:
  ```typescript
  await prisma.$transaction(async (tx) => {
    // ... operations
  }, {
    maxWait: 10000,  // max time to wait for a connection (ms)
    timeout: 30000,  // max transaction duration (ms)
  });
  ```
- Move external API calls outside the transaction — do the DB work first, commit, then call external services. Use a compensation pattern if the external call fails
- For bulk operations, batch into chunks: process 100 records per transaction instead of 10,000
- Use sequential `$transaction([query1, query2])` (batch syntax) instead of interactive transactions when you don't need to read intermediate results — batch transactions are faster and don't hold a connection open

### Relation field confusion (implicit vs explicit many-to-many)

**Symptom:** `prisma validate` fails with `Error parsing relation: ambiguous relation`. Create/connect operations on many-to-many relations produce unexpected results or fail silently. The join table has extra columns you can't access.

**Root cause:** Prisma supports two many-to-many patterns — implicit (Prisma manages the join table, no extra columns) and explicit (you define the join model, can add extra columns like `assignedAt`). Mixing patterns or misconfiguring relation names causes validation failures.

**Diagnosis:**

- Run `npx prisma validate` — it reports specific relation errors with model and field names
- Run `npx prisma format` first to normalize the schema — sometimes validation errors are caused by formatting inconsistencies
- Check whether the join table has extra columns beyond the two foreign keys — if yes, you need an explicit relation model
- Look for duplicate `@relation` names — each relation between two models needs a unique name when there are multiple relations between the same pair:
  ```prisma
  // This needs explicit @relation names
  model User {
    writtenPosts Post[] @relation("author")
    editedPosts  Post[] @relation("editor")
  }
  ```
- Inspect the database for the actual join table structure:
  ```bash
  npx prisma db pull --force
  ```
  Compare the pulled schema with your hand-written schema

**Fix pattern:**

- For simple many-to-many (no extra columns on the join): use implicit relations — just put the list field on both models. Prisma creates and manages `_ModelAToModelB` automatically
  ```prisma
  model Post {
    tags Tag[]
  }
  model Tag {
    posts Post[]
  }
  ```
- For many-to-many with extra columns (e.g., `role`, `assignedAt`): create an explicit join model with two `@relation` fields and any additional columns
  ```prisma
  model PostTag {
    post      Post     @relation(fields: [postId], references: [id])
    postId    String
    tag       Tag      @relation(fields: [tagId], references: [id])
    tagId     String
    createdAt DateTime @default(now())
    @@id([postId, tagId])
  }
  ```
- When you have multiple relations between the same two models, add unique `@relation("name")` annotations to each pair
- After fixing, run `npx prisma validate` then `npx prisma generate` to confirm resolution

## Debugging Tools

| Tool | When to use | Command |
|------|------------|---------|
| prisma migrate status | Check pending, failed, or missing migrations | `npx prisma migrate status` |
| prisma migrate diff | Compare migration state to schema or database | `npx prisma migrate diff --from-migrations ./prisma/migrations --to-schema-datamodel ./prisma/schema.prisma` |
| prisma validate | Check schema for relation errors and syntax issues | `npx prisma validate` |
| prisma format | Normalize schema formatting before validation | `npx prisma format` |
| prisma db pull | Introspect live database into schema (compare with local) | `npx prisma db pull --force` |
| prisma generate | Regenerate client after schema changes | `npx prisma generate` |
| prisma.$on('query') | Log all queries with duration for N+1 and perf diagnosis | See code snippets above |
| prisma studio | Visual database browser for inspecting data | `npx prisma studio` |
| prisma migrate reset | Wipe and recreate dev database from migrations | `npx prisma migrate reset` (dev only) |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
