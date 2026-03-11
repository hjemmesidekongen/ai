# Auth Patterns — Process Reference

## OAuth 2.0 Authorization Code + PKCE Flow

1. Generate `code_verifier` (43–128 chars, random URL-safe string)
2. Derive `code_challenge = BASE64URL(SHA256(code_verifier))`
3. Redirect to authorization server with `code_challenge`, `code_challenge_method=S256`, `response_type=code`, `state`
4. Receive `code` at redirect URI — verify `state` matches to prevent CSRF
5. Exchange `code` + `code_verifier` for tokens at the token endpoint

```ts
import { randomBytes, createHash } from 'crypto';

function generatePKCE() {
  const verifier = randomBytes(32).toString('base64url');
  const challenge = createHash('sha256')
    .update(verifier)
    .digest('base64url');
  return { verifier, challenge };
}

// Store verifier in session before redirecting
// Send challenge to authorization endpoint
```

## JWT — Signing and Validation Middleware

```ts
// lib/auth/jwt.ts
import { SignJWT, jwtVerify } from 'jose';

const privateKey = await importPKCS8(process.env.JWT_PRIVATE_KEY!, 'RS256');
const publicKey = await importSPKI(process.env.JWT_PUBLIC_KEY!, 'RS256');

export async function signToken(payload: Record<string, unknown>) {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuedAt()
    .setIssuer('https://auth.example.com')
    .setAudience('https://api.example.com')
    .setExpirationTime('15m')
    .sign(privateKey);
}

export async function verifyToken(token: string) {
  const { payload } = await jwtVerify(token, publicKey, {
    issuer: 'https://auth.example.com',
    audience: 'https://api.example.com',
  });
  return payload;
}
```

## Refresh Token Rotation

```ts
// lib/auth/refresh.ts
import { createHash, randomBytes } from 'crypto';

export async function rotateRefreshToken(oldToken: string, db: PrismaClient) {
  const hash = createHash('sha256').update(oldToken).digest('hex');
  const stored = await db.refreshToken.findUnique({ where: { hash } });

  if (!stored || stored.revokedAt) {
    // Token reuse detected — revoke entire family
    if (stored) {
      await db.refreshToken.updateMany({
        where: { family: stored.family },
        data: { revokedAt: new Date() },
      });
    }
    throw new Error('Invalid refresh token');
  }

  const newToken = randomBytes(32).toString('base64url');
  const newHash = createHash('sha256').update(newToken).digest('hex');

  await db.$transaction([
    db.refreshToken.update({ where: { hash }, data: { revokedAt: new Date() } }),
    db.refreshToken.create({
      data: {
        hash: newHash,
        family: stored.family,
        userId: stored.userId,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    }),
  ]);

  return newToken;
}
```

## NextAuth / Auth.js Configuration

```ts
// auth.ts
import NextAuth from 'next-auth';
import GitHub from 'next-auth/providers/github';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { db } from '@/lib/db';

export const { handlers, signIn, signOut, auth } = NextAuth({
  adapter: PrismaAdapter(db),
  providers: [GitHub],
  session: { strategy: 'database' }, // use 'jwt' for Edge-compatible stateless
  callbacks: {
    session({ session, user }) {
      session.user.id = user.id;
      session.user.role = user.role;
      return session;
    },
  },
  pages: { signIn: '/login' },
});
```

Protect routes in middleware:

```ts
// middleware.ts
export { auth as middleware } from '@/auth';

export const config = {
  matcher: ['/dashboard/:path*', '/api/protected/:path*'],
};
```

## RBAC Middleware

```ts
// lib/auth/rbac.ts
type Permission = 'posts:read' | 'posts:write' | 'users:manage';

const rolePermissions: Record<string, Permission[]> = {
  viewer: ['posts:read'],
  editor: ['posts:read', 'posts:write'],
  admin: ['posts:read', 'posts:write', 'users:manage'],
};

export function can(role: string, permission: Permission): boolean {
  return rolePermissions[role]?.includes(permission) ?? false;
}

// In a Server Component or Route Handler:
const session = await auth();
if (!can(session?.user?.role ?? '', 'posts:write')) {
  return new Response('Forbidden', { status: 403 });
}
```

## Password Hashing — argon2id

```ts
import argon2 from 'argon2';

export async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 65536, // 64 MiB
    timeCost: 3,
    parallelism: 4,
  });
}

export async function verifyPassword(hash: string, password: string): Promise<boolean> {
  return argon2.verify(hash, password);
}
```

For bcrypt (existing codebases): `cost: 12` minimum. Never less.

## TOTP — 2FA Setup

```ts
import { authenticator } from 'otplib';
import QRCode from 'qrcode';

export async function generateTOTPSetup(userId: string, email: string) {
  const secret = authenticator.generateSecret(); // Store encrypted in DB

  const otpauth = authenticator.keyuri(email, 'MyApp', secret);
  const qrCodeUrl = await QRCode.toDataURL(otpauth);

  return { secret, qrCodeUrl };
}

export function verifyTOTP(token: string, secret: string): boolean {
  return authenticator.verify({ token, secret });
}
```

Backup codes: generate 10 random 8-character codes, store as bcrypt hashes, mark used after redemption.

## Session Store — Redis

```ts
// lib/session.ts
import { Redis } from 'ioredis';
import { randomBytes } from 'crypto';

const redis = new Redis(process.env.REDIS_URL!);
const SESSION_TTL = 60 * 60 * 24 * 7; // 7 days

export async function createSession(userId: string): Promise<string> {
  const sessionId = randomBytes(64).toString('base64url');
  await redis.setex(`session:${sessionId}`, SESSION_TTL, JSON.stringify({ userId }));
  return sessionId;
}

export async function getSession(sessionId: string) {
  const data = await redis.get(`session:${sessionId}`);
  return data ? JSON.parse(data) : null;
}

export async function destroySession(sessionId: string) {
  await redis.del(`session:${sessionId}`);
}
```

## Social Login — Provider Wiring

OAuth state parameter prevents CSRF. Store `state` in a short-lived cookie before redirect; verify on callback. Store `code_verifier` in session for PKCE flows.

For social login without NextAuth: use `arctic` (by Lucia Auth) — lightweight, provider-agnostic OAuth helpers with PKCE and state handling built in.

## API Key Management

Generate with `crypto.randomBytes(32).toString('hex')`. Store a SHA-256 hash in DB, return plaintext once to the user. On each request: hash the incoming key, compare with stored hash. Prefix keys with an app identifier (`sk_live_`, `sk_test_`) for instant identification in logs and leak scanners. Associate keys with scopes, expiry, and last-used timestamp.

## Common Anti-Patterns with Fixes

| Anti-pattern | Fix |
|---|---|
| JWT in localStorage | httpOnly, Secure, SameSite=Strict cookie |
| No `exp` claim | Always set — 15m for access, 30d max for refresh |
| HS256 in microservices | RS256/ES256 — private key signs, public key verifies |
| No PKCE for SPAs | Required — client_secret is not safe in browser |
| Plaintext refresh tokens in DB | Store SHA-256 hash only |
| Storing TOTP secret in plaintext | Encrypt at rest with app-level key |
| `alg: none` accepted | Hardcode expected algorithm in verification call |
| No refresh token family tracking | Implement family-based revocation for theft detection |
