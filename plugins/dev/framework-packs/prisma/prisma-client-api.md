---
origin: "prisma/skills"
origin_skill: "prisma-client-api"
origin_version: "7.0.0"
forked_date: "2026-03-02"
sections_kept: "Client instantiation (v7), Model Query Methods reference, Query Options reference, CRUD examples, Transactions, Filter Operators, Relation Filters"
sections_removed: "Raw SQL section ($queryRaw, $executeRaw) — too database-specific per findings.md"
---

# Prisma Client API Reference (v7)

CRUD operations, query options, filters, and transactions for Prisma ORM 7.x.

## Client Instantiation (v7)

For full setup including singleton pattern (required for Next.js), see `prisma-database-setup.md`.

Quick reference:
```typescript
import { PrismaClient } from '../generated/client'  // path matches output in prisma.config.ts
import { PrismaPg } from '@prisma/adapter-pg'

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }) })
```

## Model Query Methods

| Method | Description |
|--------|-------------|
| `findUnique()` | Find one record by unique field |
| `findUniqueOrThrow()` | Find one or throw `NotFoundError` |
| `findFirst()` | Find first matching record |
| `findFirstOrThrow()` | Find first or throw `NotFoundError` |
| `findMany()` | Find multiple records |
| `create()` | Create a new record |
| `createMany()` | Create multiple records (no relations) |
| `createManyAndReturn()` | Create multiple and return them |
| `update()` | Update one record by unique field |
| `updateMany()` | Update multiple records |
| `updateManyAndReturn()` | Update multiple and return them |
| `upsert()` | Update or create (find-or-create) |
| `delete()` | Delete one record by unique field |
| `deleteMany()` | Delete multiple records |
| `count()` | Count matching records |
| `aggregate()` | Aggregate values (sum, avg, min, max, count) |
| `groupBy()` | Group and aggregate |

## Query Options

| Option | Description |
|--------|-------------|
| `where` | Filter conditions |
| `select` | Fields to include (exclude all others) |
| `include` | Relations to load (include with main query) |
| `omit` | Fields to exclude (include all others) |
| `orderBy` | Sort order (field: 'asc' or 'desc') |
| `take` | Limit number of results |
| `skip` | Skip results (offset pagination) |
| `cursor` | Cursor-based pagination |
| `distinct` | Unique values only |

## CRUD Examples

### Find

```typescript
// Find by unique field
const user = await prisma.user.findUnique({
  where: { email: 'alice@example.com' }
})

// Find with relations
const user = await prisma.user.findUnique({
  where: { id: 1 },
  include: { posts: { orderBy: { createdAt: 'desc' }, take: 5 } }
})

// Find many with filter and pagination
const users = await prisma.user.findMany({
  where: {
    role: 'ADMIN',
    createdAt: { gte: new Date('2024-01-01') }
  },
  orderBy: { createdAt: 'desc' },
  take: 10,
  skip: 20  // Page 3 (0-indexed)
})

// Cursor-based pagination (for infinite scroll)
const users = await prisma.user.findMany({
  take: 10,
  cursor: { id: lastUserId },
  skip: 1  // Skip the cursor itself
})

// Select specific fields
const users = await prisma.user.findMany({
  select: { id: true, email: true, name: true }
})

// Omit specific fields
const users = await prisma.user.findMany({
  omit: { password: true }  // All fields except password
})
```

### Create

```typescript
// Create with nested relation
const user = await prisma.user.create({
  data: {
    email: 'alice@example.com',
    name: 'Alice',
    posts: {
      create: [
        { title: 'First Post' },
        { title: 'Second Post' }
      ]
    }
  },
  include: { posts: true }
})

// Create many (no relation support, no individual errors)
await prisma.user.createMany({
  data: [
    { email: 'a@example.com', name: 'A' },
    { email: 'b@example.com', name: 'B' },
  ],
  skipDuplicates: true
})
```

### Update

```typescript
// Update one
const user = await prisma.user.update({
  where: { id: 1 },
  data: {
    name: 'Alice Smith',
    updatedAt: new Date()
  }
})

// Atomic number increment
await prisma.post.update({
  where: { id: 1 },
  data: { viewCount: { increment: 1 } }
})

// Update with nested relation (connect existing)
await prisma.post.update({
  where: { id: 1 },
  data: {
    author: { connect: { id: userId } }
  }
})

// Upsert (create if not found, update if found)
const user = await prisma.user.upsert({
  where: { email: 'alice@example.com' },
  update: { name: 'Alice Updated' },
  create: { email: 'alice@example.com', name: 'Alice' }
})
```

### Delete

```typescript
await prisma.user.delete({ where: { id: 1 } })

const { count } = await prisma.user.deleteMany({
  where: { createdAt: { lt: new Date('2020-01-01') } }
})
```

## Transactions

```typescript
// Sequential array transaction (all-or-nothing)
const [user, post] = await prisma.$transaction([
  prisma.user.create({ data: { email: 'a@example.com' } }),
  prisma.post.create({ data: { title: 'Hello', authorId: 1 } })
])

// Interactive transaction (more control, supports logic between operations)
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email: 'a@example.com' } })
  const post = await tx.post.create({
    data: { title: 'Hello', authorId: user.id }
  })
  return { user, post }
})

// Transaction with retry and timeout options
await prisma.$transaction(async (tx) => {
  // ...
}, {
  maxWait: 5000,   // Max wait for transaction slot (ms)
  timeout: 10000,  // Max transaction duration (ms)
  isolationLevel: 'Serializable'
})
```

## Filter Operators

```typescript
where: {
  name: { equals: 'Alice' },           // Exact match (also: name: 'Alice')
  name: { not: 'Bob' },                // Not equal
  id: { in: [1, 2, 3] },              // In array
  id: { notIn: [4, 5] },              // Not in array
  age: { lt: 30 },                     // Less than
  age: { lte: 30 },                    // Less than or equal
  age: { gt: 18 },                     // Greater than
  age: { gte: 18 },                    // Greater than or equal
  email: { contains: '@example.com' }, // String contains
  name: { startsWith: 'A' },           // String starts with
  name: { endsWith: 'Smith' },         // String ends with
  email: { contains: 'ALICE', mode: 'insensitive' }, // Case insensitive
}

// Logical operators
where: {
  AND: [{ role: 'ADMIN' }, { active: true }],
  OR: [{ email: 'a@example.com' }, { email: 'b@example.com' }],
  NOT: { banned: true },
}

// Null checks
where: {
  deletedAt: null,                    // IS NULL
  deletedAt: { not: null },           // IS NOT NULL
}
```

## Relation Filters

```typescript
// Posts where at least one comment matches
where: {
  posts: { some: { published: true } }
}

// Users where ALL posts are published
where: {
  posts: { every: { published: true } }
}

// Users with no comments
where: {
  comments: { none: {} }
}

// Posts with specific author (1-to-1 or many-to-1)
where: {
  author: { is: { role: 'ADMIN' } },
  author: { isNot: { banned: true } }
}
```

## Client Methods

```typescript
await prisma.$connect()         // Explicit connection (optional, auto-connects on first query)
await prisma.$disconnect()      // Disconnect (call in cleanup/shutdown)
await prisma.$transaction([])   // Run transaction
prisma.$extends({})             // Add extensions (replaces v6 middleware)
prisma.$on('query', handler)    // Subscribe to query events
```
