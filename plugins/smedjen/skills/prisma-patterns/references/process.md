# prisma-patterns — Process Reference

## 1. Schema Design Patterns

### Relations

```prisma
model User {
  id    Int    @id @default(autoincrement())
  posts Post[]
}

model Post {
  id       Int  @id @default(autoincrement())
  authorId Int
  author   User @relation(fields: [authorId], references: [id])

  @@index([authorId])
}
```

Always index the FK side (`authorId`). For many-to-many, use an explicit join model when the relation carries data (e.g., `role`, `joinedAt`). Use Prisma's implicit m2m only for pure join tables with no payload.

### Enums

```prisma
enum Status {
  DRAFT
  PUBLISHED
  ARCHIVED
}

model Post {
  status Status @default(DRAFT)
}
```

Enums are enforced at the DB level. Adding a value requires a migration. If values change frequently, use `String` + application validation instead.

### Composite Types (MongoDB only)

```prisma
type Address {
  street String
  city   String
  zip    String
}

model User {
  address Address
}
```

### Naming Conventions — @@map / @map

```prisma
model UserProfile {
  id        Int    @id
  firstName String @map("first_name")

  @@map("user_profiles")
}
```

Use `@@map` to keep DB table names snake_case while Prisma models are PascalCase. Use `@map` for column name normalization. This separates DB conventions from application layer naming.

### Composite Index and Unique Constraints

```prisma
model Post {
  slug      String
  tenantId  Int

  @@unique([tenantId, slug])
  @@index([tenantId, status])  // include status if filtered together
}
```

---

## 2. Migration Workflow

### Development Loop

```bash
# Schema change → generate migration → apply → regenerate client
npx prisma migrate dev --name add_user_profile

# Preview SQL before applying
npx prisma migrate dev --create-only
```

### Production Deploy

```bash
# CI/CD — applies pending migrations, no generation
npx prisma migrate deploy
```

### Baseline a Legacy Database

```bash
# Mark existing state as applied without running SQL
npx prisma migrate resolve --applied "20240101_init"
```

### Squashing Migrations (dev only)

During active development before first production deploy, squash by deleting the `prisma/migrations` directory and running `migrate dev` fresh. Never squash after any migration has been deployed.

---

## 3. Seeding

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      email: 'admin@example.com',
      name: 'Admin',
      role: 'ADMIN',
    },
  })
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
```

```json
// package.json
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

Run with `npx prisma db seed`. Use `upsert` in seeds so they're idempotent — safe to re-run without duplicating data.

---

## 4. Query Patterns

### Select — Project Only What You Need

```typescript
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true,
  },
})
```

Never pull full records when only a subset is rendered. `select` at the call site is cheaper than filtering in application code.

### Include — Eager Load Relations

```typescript
const posts = await prisma.post.findMany({
  where: { published: true },
  include: {
    author: { select: { name: true } },
    tags: true,
  },
  orderBy: { createdAt: 'desc' },
  take: 20,
})
```

Nest `select` inside `include` to limit the relation fields loaded.

### Where — Filter Patterns

```typescript
// IN clause for batch lookup
const users = await prisma.user.findMany({
  where: { id: { in: userIds } },
})

// Full-text search (PostgreSQL)
const results = await prisma.post.findMany({
  where: {
    title: { search: 'prisma patterns' },
  },
})

// Compound filter
const posts = await prisma.post.findMany({
  where: {
    AND: [
      { published: true },
      { createdAt: { gte: startDate } },
    ],
  },
})
```

### Nested Writes

```typescript
// Create user + related posts in one call
const user = await prisma.user.create({
  data: {
    email: 'user@example.com',
    posts: {
      create: [
        { title: 'First Post', published: false },
      ],
    },
  },
})

// Connect existing records
await prisma.post.update({
  where: { id: postId },
  data: {
    tags: { connect: [{ id: tagId }] },
  },
})
```

### Cursor-Based Pagination

```typescript
const page = await prisma.post.findMany({
  take: 20,
  skip: 1,          // skip the cursor itself
  cursor: { id: lastId },
  orderBy: { id: 'asc' },
})
```

Offset pagination (`skip: page * size`) degrades as offsets grow large. Use cursor pagination for large datasets or infinite scroll.

---

## 5. Transactions

### Sequential (array form)

```typescript
const [user, account] = await prisma.$transaction([
  prisma.user.create({ data: { email } }),
  prisma.account.create({ data: { userId } }),  // userId not available until above resolves
])
```

Note: array transactions run in parallel internally. Use interactive form when operations depend on each other's results.

### Interactive Transaction

```typescript
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email } })

  const account = await tx.account.create({
    data: { userId: user.id, balance: 0 },
  })

  if (account.balance < 0) {
    throw new Error('Invalid initial balance')  // auto-rollback
  }

  return { user, account }
})
```

Throw inside the callback to trigger rollback. Keep transactions as short as possible — they hold locks until committed.

---

## 6. Raw Queries

### $queryRaw — Typed Read

```typescript
import { Prisma } from '@prisma/client'

const results = await prisma.$queryRaw<Array<{ id: number; name: string }>>`
  SELECT id, name FROM users
  WHERE created_at > ${startDate}
  ORDER BY name ASC
`
```

Use tagged template literals — Prisma parameterizes them safely. Never concatenate user input into raw SQL.

### $executeRaw — Write

```typescript
const affected = await prisma.$executeRaw`
  UPDATE posts SET view_count = view_count + 1
  WHERE id = ${postId}
`
```

Returns the number of affected rows.

### When to Reach for Raw

- Window functions (`ROW_NUMBER`, `RANK`, `LAG`)
- CTEs for recursive queries
- Full-text search with ranking
- Bulk upserts with conflict resolution
- DB-specific JSON operations

---

## 7. Connection Pooling

Prisma uses a built-in connection pool. Default: `min: 2`, `max: 10` per process.

```typescript
// Explicit configuration via datasource URL params
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")  // ?connection_limit=5&pool_timeout=10
}
```

For serverless (Vercel, Cloudflare Workers), use **Prisma Accelerate** or **PgBouncer** — serverless functions create a new Prisma Client per invocation, which exhausts DB connections fast. Store the client in a module-level singleton:

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }

export const prisma =
  globalForPrisma.prisma ?? new PrismaClient({ log: ['error'] })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

---

## 8. Prisma Client Extensions

```typescript
const prisma = new PrismaClient().$extends({
  model: {
    user: {
      async findByEmail(email: string) {
        return prisma.user.findUnique({ where: { email } })
      },
    },
  },
})

await prisma.user.findByEmail('user@example.com')
```

Extensions are composable. Use them for domain-specific query helpers, not for business logic.

---

## 9. Middleware

```typescript
prisma.$use(async (params, next) => {
  const before = Date.now()
  const result = await next(params)
  console.log(`${params.model}.${params.action} — ${Date.now() - before}ms`)
  return result
})
```

Middleware runs on every query. Keep it lightweight. Use for cross-cutting concerns: logging, soft delete filtering, tenant scoping.

---

## 10. Soft Deletes Pattern

```prisma
model Post {
  id        Int       @id @default(autoincrement())
  deletedAt DateTime?

  @@index([deletedAt])
}
```

```typescript
// Middleware to filter soft-deleted records
prisma.$use(async (params, next) => {
  if (params.model === 'Post' && params.action === 'findMany') {
    params.args.where = {
      ...params.args.where,
      deletedAt: null,
    }
  }
  return next(params)
})

// Soft delete
await prisma.post.update({
  where: { id },
  data: { deletedAt: new Date() },
})
```

Middleware-based filtering is implicit — ensure the team understands it exists. Document it clearly. For complex cases, consider explicit `isDeleted` boolean with a named scope helper instead.

---

## 11. Multi-Tenancy

### Row-Level Tenancy (most common)

```prisma
model Post {
  id       Int @id @default(autoincrement())
  tenantId Int

  @@index([tenantId])
}
```

```typescript
// Middleware — enforce tenantId on all reads/writes
prisma.$use(async (params, next) => {
  const tenantId = getTenantFromContext()

  if (params.action === 'findMany' || params.action === 'findFirst') {
    params.args.where = { ...params.args.where, tenantId }
  }

  return next(params)
})
```

Always index `tenantId`. Every query should hit the tenant index first.

### Schema-Per-Tenant (PostgreSQL)

Use `SET search_path = tenant_<id>` via `$executeRaw` before queries. Requires a separate Prisma Client instance per request or connection pinning. Operationally heavier — use only when strict data isolation is a compliance requirement.

---

## 12. Common Anti-Patterns

### N+1 — Most Common Prisma Bug

```typescript
// BAD — fires one query per post
const posts = await prisma.post.findMany()
for (const post of posts) {
  const author = await prisma.user.findUnique({ where: { id: post.authorId } })
}

// GOOD — single query with include
const posts = await prisma.post.findMany({
  include: { author: true },
})
```

Detect N+1 by enabling query logging in development: `new PrismaClient({ log: ['query'] })`.

### Missing Indexes

```prisma
// BAD — filtering on email without index
model User {
  email String
}

// GOOD
model User {
  email String @unique  // creates index automatically
}

// Or for non-unique fields used in where/orderBy:
model Post {
  @@index([authorId, createdAt])
}
```

Any field that appears regularly in `where`, `orderBy`, or relation joins needs an index.

### Over-Fetching

```typescript
// BAD — loads all fields including large blobs
const users = await prisma.user.findMany()

// GOOD — select only what the view needs
const users = await prisma.user.findMany({
  select: { id: true, name: true, email: true },
})
```

### Unbounded findMany

```typescript
// BAD — could return millions of rows
const allPosts = await prisma.post.findMany()

// GOOD
const posts = await prisma.post.findMany({
  take: 100,
  orderBy: { createdAt: 'desc' },
})
```

Always add `take` to `findMany` unless you have an explicit, justified reason to load all records.

### Prisma Client Per Request (Serverless)

```typescript
// BAD — new client on every invocation
export default async function handler(req, res) {
  const prisma = new PrismaClient()
  // ...
}

// GOOD — singleton from lib/prisma.ts
import { prisma } from '@/lib/prisma'
```
