---
origin: "prisma/skills"
origin_skill: "prisma-database-setup"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "PostgreSQL and SQLite sections only, driver adapter table, Client Setup steps, Prisma v7 prerequisites"
sections_removed: "MySQL, MongoDB, SQL Server, CockroachDB, Prisma Postgres sections — only PostgreSQL and SQLite kept per findings.md (most common in web projects)"
---

# Prisma Database Setup (PostgreSQL + SQLite)

Connection setup for the two most common web project databases. For MySQL, CockroachDB, or SQL Server, see the full upstream skill.

> See also: `prisma-client-api.md` for CRUD operations, query options, filters, and transactions. `prisma-cli.md` for migration commands. `prisma-upgrade-v7.md` for upgrading from v6.

## System Prerequisites (Prisma v7)

- Node.js 20.19.0+
- TypeScript 5.4.0+

## Driver Adapters (Required in v7)

All databases require a driver adapter in Prisma v7:

| Database | Adapter | Driver |
|----------|---------|--------|
| PostgreSQL | `@prisma/adapter-pg` | `pg` |
| SQLite | `@prisma/adapter-better-sqlite3` | `better-sqlite3` |
| SQLite (Turso) | `@prisma/adapter-libsql` | `@libsql/client` |
| MySQL | `@prisma/adapter-mariadb` | `mariadb` |
| Prisma Postgres | `@prisma/adapter-ppg` | `@prisma/ppg` |
| Neon | `@prisma/adapter-neon` | (bundled) |

## PostgreSQL Setup

### Install

```bash
npm install @prisma/client@7
npm install -D prisma@7
npm install @prisma/adapter-pg pg
npm install -D @types/pg
npm install dotenv
```

### schema.prisma

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client"
  output   = "../generated"
}
```

### prisma.config.ts

```typescript
import 'dotenv/config'
import { defineConfig, env } from 'prisma/config'

export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: {
    url: env('DATABASE_URL'),
  },
})
```

### .env

```env
# Standard PostgreSQL connection string
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE"

# With SSL (common for cloud databases like Supabase, Neon, RDS)
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=require"

# Local development
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/myapp"
```

### Client Instantiation

```typescript
// lib/db.ts
import { PrismaClient } from '../generated/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
  // SSL for cloud databases
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined,
})

export const prisma = new PrismaClient({ adapter })
```

**Singleton pattern for Next.js (prevents connection pool exhaustion in development):**

```typescript
// lib/db.ts
import { PrismaClient } from '../generated/client'
import { PrismaPg } from '@prisma/adapter-pg'

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }

function createPrismaClient() {
  const adapter = new PrismaPg({
    connectionString: process.env.DATABASE_URL!,
  })
  return new PrismaClient({ adapter })
}

export const prisma = globalForPrisma.prisma ?? createPrismaClient()

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma
}
```

## SQLite Setup

SQLite is file-based — no connection string complexity, ideal for development and edge deployments.

### Install

```bash
npm install @prisma/client@7
npm install -D prisma@7
npm install @prisma/adapter-better-sqlite3 better-sqlite3
npm install -D @types/better-sqlite3
```

### schema.prisma

```prisma
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client"
  output   = "../generated"
}
```

### .env

```env
# SQLite file path (relative to prisma directory or absolute)
DATABASE_URL="file:./dev.db"

# Absolute path
DATABASE_URL="file:/absolute/path/to/database.db"
```

### Client Instantiation

```typescript
// lib/db.ts
import { PrismaClient } from '../generated/client'
import { PrismaBetterSQLite3 } from '@prisma/adapter-better-sqlite3'
import Database from 'better-sqlite3'

const dbPath = process.env.DATABASE_URL!.replace('file:', '')
const database = new Database(dbPath)
const adapter = new PrismaBetterSQLite3(database)

export const prisma = new PrismaClient({ adapter })
```

### SQLite Limitations

- No enum support (use String with validation)
- No scalar list fields
- Single writer (not for high-concurrency production)
- No native JSON operator support

## Initial Setup Steps (Both Databases)

1. Install packages (see above)
2. Update `schema.prisma` with provider and generator
3. Create `prisma.config.ts` with `import 'dotenv/config'`
4. Set `DATABASE_URL` in `.env`
5. Create initial migration:
   ```bash
   npx prisma migrate dev --name init
   ```
6. Generate client:
   ```bash
   npx prisma generate
   ```

## Troubleshooting

**"Can't reach database server"**
- PostgreSQL: Check host, port, credentials in `DATABASE_URL`
- SQLite: Check file path exists and is writable

**"SSL connection error"**
- Add `?sslmode=require` to connection string
- Or set `ssl: { rejectUnauthorized: false }` on adapter (dev only)

**"Permission denied for table"**
- PostgreSQL: Grant permissions to database user
- SQLite: Check file system permissions

**"Output path not found"**
- Run `npx prisma generate` to create the `generated/` directory
