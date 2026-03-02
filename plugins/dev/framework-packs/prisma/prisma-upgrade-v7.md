---
origin: "prisma/skills"
origin_skill: "prisma-upgrade-v7"
origin_version: "7.0.0"
forked_date: "2026-03-02"
sections_kept: "All sections — breaking changes summary, step-by-step migration (ESM, tsconfig, schema, prisma.config.ts, driver adapters, client instantiation), troubleshooting"
sections_removed: "None — kept in full per findings.md recommendation (critical for preventing v6/v7 pattern confusion)"
---

# Prisma ORM v7 Upgrade Guide

Complete migration from Prisma v6 to v7. **Critical reference** — v7 is ESM-only with mandatory driver adapters. Agents without this context generate broken code.

## When to Apply

- Upgrading from Prisma v6 to v7
- Setting up a new Prisma project (use v7 patterns)
- Fixing import errors after upgrade
- Reviewing generated Prisma code for version accuracy

## Breaking Changes Summary

| Change | v6 | v7 |
|--------|----|----|
| Module format | CommonJS | **ESM only** |
| Generator provider | `prisma-client-js` | `prisma-client` |
| Output path | Auto (node_modules) | **Required explicit** |
| Driver adapters | Optional | **Required** |
| Config file | `.env` + schema | **`prisma.config.ts`** |
| Env loading | Automatic | Manual (dotenv) |
| Middleware | `$use()` | Client Extensions |
| Metrics | Preview feature | Removed |

## Important Notes

- **MongoDB not yet supported in v7** — Continue using v6 for MongoDB
- **Node.js 20.19.0+** required
- **TypeScript 5.4.0+** required

## Step 1: Update Packages

```bash
npm install @prisma/client@7
npm install -D prisma@7
npm install dotenv
```

## Step 2: Configure ESM (package.json)

```json
{
  "type": "module"
}
```

## Step 3: Update TypeScript Config

```json
{
  "compilerOptions": {
    "module": "ESNext",
    "moduleResolution": "bundler",
    "target": "ES2023",
    "strict": true,
    "esModuleInterop": true
  }
}
```

## Step 4: Update schema.prisma

```prisma
// ❌ v6
generator client {
  provider = "prisma-client-js"
}

// ✅ v7
generator client {
  provider = "prisma-client"
  output   = "../generated"
}
```

The `output` path is **required** in v7. It must match the import path in your code.

## Step 5: Create prisma.config.ts

```typescript
import 'dotenv/config'
import { defineConfig, env } from 'prisma/config'

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url: env('DATABASE_URL'),
  },
})
```

## Step 6: Install Driver Adapter

Driver adapters are **mandatory** in v7:

```bash
# PostgreSQL (most common)
npm install @prisma/adapter-pg

# MySQL / MariaDB
npm install @prisma/adapter-mariadb mariadb

# SQLite
npm install @prisma/adapter-better-sqlite3

# Prisma Postgres (managed)
npm install @prisma/adapter-ppg @prisma/ppg

# Neon
npm install @prisma/adapter-neon

# Turso / LibSQL
npm install @prisma/adapter-libsql @libsql/client
```

## Step 7: Update Client Instantiation

```typescript
// ❌ v6
import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

// ✅ v7 (PostgreSQL example)
import { PrismaClient } from '../generated/client'
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL
})
const prisma = new PrismaClient({ adapter })
```

## Step 8: Removed Features

**Middleware removed** — use Client Extensions instead:
```typescript
// ❌ v6 middleware
prisma.$use(async (params, next) => {
  const result = await next(params)
  return result
})

// ✅ v7 Client Extension
const prisma = new PrismaClient().$extends({
  query: {
    async $allOperations({ args, query }) {
      const result = await query(args)
      return result
    }
  }
})
```

**Removed CLI flags:**
- `--skip-generate` removed from `migrate dev` and `db push`
- `--skip-seed` removed from `migrate dev`
- `--schema` and `--url` removed from `db execute`
- Run `prisma generate` explicitly after migrations

## Step 9: Run Generate and Test

```bash
npx prisma generate
npx prisma migrate dev  # if schema changed
```

## Troubleshooting

**"Cannot find module '../generated/client'"**
- Check `output` path in generator block matches import path
- Run `npx prisma generate`

**"Driver adapter required"**
- v7 requires explicit driver adapter — see Step 6

**SSL certificate errors**
- Add `ssl: { rejectUnauthorized: false }` to adapter config (dev only)

**"$use is not a function"**
- Middleware removed in v7 — migrate to Client Extensions

**Environment variables not loading**
- v7 no longer auto-loads `.env` — add `import 'dotenv/config'` to `prisma.config.ts`

**Bun runtime:**
```bash
bunx --bun prisma generate
bunx --bun prisma migrate dev
```
