# API Security — Process Reference

## Rate Limiting — Redis Sliding Window

```ts
// lib/rate-limit.ts
import { Redis } from 'ioredis';

const redis = new Redis(process.env.REDIS_URL!);

export async function slidingWindowRateLimit(
  key: string,
  limit: number,
  windowMs: number
): Promise<{ allowed: boolean; remaining: number; resetAt: number }> {
  const now = Date.now();
  const windowStart = now - windowMs;

  const pipeline = redis.pipeline();
  pipeline.zremrangebyscore(key, 0, windowStart);
  pipeline.zadd(key, now, `${now}-${Math.random()}`);
  pipeline.zcount(key, windowStart, '+inf');
  pipeline.pexpire(key, windowMs);

  const results = await pipeline.exec();
  const count = results![2][1] as number;

  return {
    allowed: count <= limit,
    remaining: Math.max(0, limit - count),
    resetAt: now + windowMs,
  };
}
```

Express middleware wrapper:

```ts
// middleware/rate-limit.ts
import { Request, Response, NextFunction } from 'express';
import { slidingWindowRateLimit } from '@/lib/rate-limit';

export function rateLimit(limit: number, windowMs: number) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const key = `rl:${req.user?.id ?? req.ip}:${req.path}`;
    const result = await slidingWindowRateLimit(key, limit, windowMs);

    res.setHeader('X-RateLimit-Limit', limit);
    res.setHeader('X-RateLimit-Remaining', result.remaining);
    res.setHeader('X-RateLimit-Reset', Math.ceil(result.resetAt / 1000));

    if (!result.allowed) {
      res.setHeader('Retry-After', Math.ceil(windowMs / 1000));
      return res.status(429).json({ error: 'Too many requests' });
    }

    next();
  };
}

// Usage
router.post('/auth/login', rateLimit(5, 60_000), loginHandler); // 5 req/min
router.post('/auth/otp', rateLimit(3, 300_000), otpHandler);    // 3 req/5min
```

## Input Validation — zod Middleware

```ts
// middleware/validate.ts
import { z, ZodSchema } from 'zod';
import { Request, Response, NextFunction } from 'express';

export function validate<T>(schema: ZodSchema<T>, source: 'body' | 'query' | 'params' = 'body') {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req[source]);

    if (!result.success) {
      return res.status(400).json({
        error: 'Validation failed',
        issues: result.error.issues.map(i => ({
          path: i.path.join('.'),
          message: i.message,
        })),
      });
    }

    req[source] = result.data; // Replace with parsed/coerced data
    next();
  };
}

// Schema definition
const CreateUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(12).max(128),
  role: z.enum(['viewer', 'editor']).default('viewer'),
  name: z.string().min(1).max(100).trim(),
});

// Usage
router.post('/users', validate(CreateUserSchema), createUserHandler);
```

## CORS Configuration

```ts
// middleware/cors.ts
import cors from 'cors';

const allowedOrigins = process.env.ALLOWED_ORIGINS!.split(',');

export const corsMiddleware = cors({
  origin(origin, callback) {
    // Allow requests with no origin (e.g., mobile apps, curl)
    if (!origin) return callback(null, true);

    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`Origin ${origin} not allowed by CORS`));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  exposedHeaders: ['X-RateLimit-Remaining', 'X-RateLimit-Reset'],
  maxAge: 86400,
});
```

Environment config:
```
# .env.production
ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
# .env.development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
```

## Security Headers — Helmet.js

```ts
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],        // Add CDNs/nonces as needed
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      frameAncestors: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,     // 1 year
    includeSubDomains: true,
    preload: true,
  },
}));
```

To audit headers: `curl -I https://yourdomain.com` or check with securityheaders.com.

## Request Sanitization

### HTML Sanitization (user-generated content)

```ts
import sanitizeHtml from 'sanitize-html';

export function sanitizeContent(dirty: string): string {
  return sanitizeHtml(dirty, {
    allowedTags: ['b', 'i', 'em', 'strong', 'a', 'p', 'ul', 'ol', 'li', 'br'],
    allowedAttributes: {
      a: ['href', 'target', 'rel'],
    },
    allowedSchemes: ['http', 'https', 'mailto'],
    transformTags: {
      a: (tagName, attribs) => ({
        tagName,
        attribs: { ...attribs, rel: 'noopener noreferrer' },
      }),
    },
  });
}
```

### Path Traversal Prevention

```ts
import path from 'path';

export function safePath(baseDir: string, userInput: string): string {
  const resolved = path.resolve(baseDir, userInput);

  if (!resolved.startsWith(path.resolve(baseDir))) {
    throw new Error('Path traversal detected');
  }

  return resolved;
}
```

### MongoDB Operator Injection Prevention

```ts
import { z } from 'zod';

// Reject strings starting with $ in any nested field
const noMongoOperators = z.string().refine(
  val => !val.startsWith('$'),
  { message: 'Invalid input' }
);

// Or strip operators from query objects:
function sanitizeMongoQuery(obj: unknown): unknown {
  if (typeof obj !== 'object' || obj === null) return obj;
  return Object.fromEntries(
    Object.entries(obj as Record<string, unknown>)
      .filter(([key]) => !key.startsWith('$'))
      .map(([key, val]) => [key, sanitizeMongoQuery(val)])
  );
}
```

## API Key Management

```ts
// lib/api-keys.ts
import { randomBytes, createHash } from 'crypto';

const PREFIX = 'sk_live_';

export function generateApiKey(): { key: string; hash: string } {
  const raw = randomBytes(32).toString('hex');
  const key = `${PREFIX}${raw}`;
  const hash = createHash('sha256').update(key).digest('hex');
  return { key, hash }; // Return key to user once; store only hash
}

export function hashApiKey(key: string): string {
  return createHash('sha256').update(key).digest('hex');
}

// Middleware
export async function apiKeyAuth(req: Request, res: Response, next: NextFunction) {
  const key = req.headers['x-api-key'] as string;
  if (!key) return res.status(401).json({ error: 'API key required' });

  const hash = hashApiKey(key);
  const apiKey = await db.apiKey.findUnique({
    where: { hash },
    include: { user: true },
  });

  if (!apiKey || apiKey.revokedAt || (apiKey.expiresAt && apiKey.expiresAt < new Date())) {
    return res.status(401).json({ error: 'Invalid or expired API key' });
  }

  // Update last-used asynchronously — don't block the request
  db.apiKey.update({ where: { id: apiKey.id }, data: { lastUsedAt: new Date() } }).catch(() => {});

  req.user = apiKey.user;
  next();
}
```

## Body Size Limits

```ts
import express from 'express';

// Global default — tighten for most routes
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// Override for specific routes that legitimately need more
router.post('/upload/metadata', express.json({ limit: '1mb' }), uploadHandler);
```

## NestJS Guard Patterns

```ts
// guards/rate-limit.guard.ts
import { Injectable, CanActivate, ExecutionContext, HttpException } from '@nestjs/common';
import { slidingWindowRateLimit } from '@/lib/rate-limit';

@Injectable()
export class RateLimitGuard implements CanActivate {
  constructor(private limit: number, private windowMs: number) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const key = `rl:${req.user?.id ?? req.ip}:${req.path}`;
    const result = await slidingWindowRateLimit(key, this.limit, this.windowMs);

    if (!result.allowed) {
      throw new HttpException('Too many requests', 429);
    }
    return true;
  }
}

// Usage on controller
@UseGuards(new RateLimitGuard(10, 60_000))
@Post('login')
async login(@Body() dto: LoginDto) { ... }
```

## HTTPS Enforcement (Express)

```ts
// Redirect HTTP to HTTPS in production (if not handled by load balancer)
app.use((req, res, next) => {
  if (process.env.NODE_ENV === 'production' && req.headers['x-forwarded-proto'] !== 'https') {
    return res.redirect(301, `https://${req.headers.host}${req.url}`);
  }
  next();
});
```

Prefer handling this at the load balancer (nginx, ALB) — it's faster and more reliable than in-process.

## IP Allowlisting for Admin Routes

```ts
const ADMIN_IP_ALLOWLIST = process.env.ADMIN_IPS!.split(',');

function ipAllowlist(req: Request, res: Response, next: NextFunction) {
  const clientIp = req.headers['x-forwarded-for']?.toString().split(',')[0].trim() ?? req.ip;
  if (!ADMIN_IP_ALLOWLIST.includes(clientIp)) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  next();
}

router.use('/admin', ipAllowlist);
```

## Structured Security Logging

```ts
// Log all auth failures and suspicious patterns
app.use((req, res, next) => {
  res.on('finish', () => {
    if (res.statusCode === 401 || res.statusCode === 403 || res.statusCode === 429) {
      console.log(JSON.stringify({
        ts: new Date().toISOString(),
        status: res.statusCode,
        method: req.method,
        path: req.path,
        ip: req.ip,
        userId: req.user?.id ?? null,
        userAgent: req.headers['user-agent'],
      }));
    }
  });
  next();
});
```

Never log: passwords, tokens, API keys, full request bodies on auth endpoints, PII.

## Common Anti-Patterns with Fixes

| Anti-pattern | Fix |
|---|---|
| No rate limit on `/auth/login` | 5 req/min per IP, lock account after 10 failures |
| `Access-Control-Allow-Origin: *` + `credentials: true` | Invalid combination — browsers reject it; use explicit origin list |
| Raw SQL: `WHERE id = ${req.params.id}` | Parameterized query: `WHERE id = $1` with `[req.params.id]` |
| Body size unbounded | Set `limit: '10kb'` on `express.json()` |
| Logging `req.body` on auth routes | Exclude password/token fields from logs |
| `Content-Security-Policy: *` | Start with `default-src 'self'`, expand only what you need |
| Missing `Retry-After` on 429 | Always include — clients need it for backoff |
