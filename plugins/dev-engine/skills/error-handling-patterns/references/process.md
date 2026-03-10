# Error Handling Patterns — Reference

## Custom Error Classes

Define typed errors for every domain boundary. Generic `Error` gives you nothing to act on.

**TypeScript base pattern:**
```ts
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly context?: Record<string, unknown>
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found`, 'NOT_FOUND', 404, { resource, id });
  }
}

class ValidationError extends AppError {
  constructor(message: string, public readonly fields: Record<string, string>) {
    super(message, 'VALIDATION_ERROR', 422, { fields });
  }
}

class ExternalServiceError extends AppError {
  constructor(service: string, cause?: Error) {
    super(`${service} unavailable`, 'EXTERNAL_SERVICE_ERROR', 503, { service });
    if (cause) this.cause = cause;
  }
}
```

Naming convention: `<Domain><Kind>Error`. Keep the hierarchy shallow — avoid deep inheritance chains.

---

## TypeScript Patterns

**Typed catch with narrowing:**
```ts
try {
  await fetchUser(id);
} catch (err) {
  if (err instanceof NotFoundError) {
    return null; // recover
  }
  if (err instanceof ExternalServiceError) {
    throw err; // let the retry layer handle it
  }
  // unexpected — re-throw with context
  throw new AppError('Unexpected failure in fetchUser', 'UNKNOWN', 500, { id, cause: err });
}
```

**Result type (functional style):**
```ts
type Result<T, E = AppError> = { ok: true; value: T } | { ok: false; error: E };

async function parseConfig(raw: string): Promise<Result<Config>> {
  try {
    return { ok: true, value: JSON.parse(raw) };
  } catch {
    return { ok: false, error: new ValidationError('Invalid config JSON', {}) };
  }
}
```

Use Result types at module boundaries where callers need to handle both paths without try-catch noise.

---

## Node.js Patterns

**Express error-handling middleware:**
```ts
app.use((err: unknown, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError) {
    logger.warn({ code: err.code, context: err.context }, err.message);
    return res.status(err.statusCode).json({
      error: err.code,
      message: err.message,
    });
  }

  // Unexpected — log full stack, hide details from client
  logger.error({ err }, 'Unhandled error');
  res.status(500).json({ error: 'INTERNAL_ERROR', message: 'Something went wrong.' });
});
```

**Async route wrapper** (avoids unhandled promise rejections):
```ts
const asyncRoute = (fn: RequestHandler): RequestHandler =>
  (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

app.get('/users/:id', asyncRoute(async (req, res) => {
  const user = await getUser(req.params.id);
  res.json(user);
}));
```

**Global handlers — last line of defense only:**
```ts
process.on('unhandledRejection', (reason) => {
  logger.fatal({ reason }, 'Unhandled rejection — shutting down');
  process.exit(1);
});
```

---

## React Error Boundaries

```tsx
class ErrorBoundary extends React.Component<
  { fallback: React.ReactNode; children: React.ReactNode },
  { hasError: boolean; error?: Error }
> {
  state = { hasError: false };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    logger.error({ error, componentStack: info.componentStack }, 'React render error');
  }

  render() {
    return this.state.hasError ? this.props.fallback : this.props.children;
  }
}
```

**Placement strategy:**
- Root boundary: catches everything, shows a full-page error state
- Feature boundary: isolates a widget/panel; rest of UI stays functional
- Data boundary: wrap async data-dependent subtrees individually

Avoid a single root-only boundary — one broken component shouldn't take down the whole page.

---

## Logging Strategy

**Structured logs with context:**
```ts
// Bad
console.error('Failed to fetch user ' + id);

// Good
logger.error({ userId: id, correlationId: req.headers['x-correlation-id'], err }, 'User fetch failed');
```

Fields every log entry should carry:
- `correlationId` / `requestId` — trace a request across services
- `userId` — when available and relevant
- `err` — the serialized error object (pino serializes `.stack` automatically)
- `context` — any domain-specific state needed to reproduce

**Log levels by audience:**
| Level | Meaning | Alerted? |
|-------|---------|----------|
| `fatal` | Process must exit | Yes |
| `error` | Request/job failed, needs investigation | Yes |
| `warn` | Degraded path taken, worth tracking | Maybe |
| `info` | Normal lifecycle events | No |
| `debug` | Developer detail, off in prod | No |

---

## Retry Patterns

**Exponential backoff with jitter:**
```ts
async function withRetry<T>(
  fn: () => Promise<T>,
  { maxAttempts = 3, baseDelayMs = 200 }: RetryOptions = {}
): Promise<T> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxAttempts || !(err instanceof ExternalServiceError)) throw err;
      const delay = baseDelayMs * 2 ** (attempt - 1) + Math.random() * 100;
      await new Promise((r) => setTimeout(r, delay));
    }
  }
  throw new Error('unreachable');
}
```

Only retry on transient errors (network, rate limit, 503). Never retry `ValidationError` or `NotFoundError` — they won't resolve.

---

## Circuit Breaker

Prevent cascading failures when a downstream service is consistently failing.

States: `CLOSED` (normal) → `OPEN` (failing, reject fast) → `HALF_OPEN` (probe allowed) → back to `CLOSED` or `OPEN`.

Use a library (`opossum` for Node) rather than rolling your own. Configuration keys:
- `errorThresholdPercentage`: failure rate to trip the breaker (e.g., 50%)
- `resetTimeout`: ms to wait before probing (e.g., 10000)
- `volumeThreshold`: min calls before evaluating (e.g., 5)

---

## Anti-Patterns

**Swallowing errors:**
```ts
// Never do this
try {
  await saveRecord(data);
} catch (_) {
  // silent
}
```
If you catch and do nothing, the failure is invisible. At minimum, log it. If recovery isn't possible, re-throw.

**Catch-all without re-throw:**
```ts
// Bad — hides real error type from callers
catch (err) {
  logger.error(err);
  return null;
}
```

**Error as control flow:**
```ts
// Bad — using exceptions to signal expected absence
try {
  const user = await getUser(id); // throws NotFoundError if missing
  return user;
} catch {
  return defaultUser;
}
// Better: getUser returns null for not-found, throws only on unexpected failure
```

**Exposing internals to users:**
```ts
// Never send stack traces or internal error codes to clients
res.status(500).json({ error: err.stack }); // exposes internals
```

**Over-broad catch in async loops:**
```ts
// Bad — one failure stops all items
for (const item of items) {
  try {
    await process(item);
  } catch (err) {
    throw err; // kills the whole batch
  }
}

// Better — collect failures, continue processing
const failures: Array<{ item: Item; error: unknown }> = [];
for (const item of items) {
  try {
    await process(item);
  } catch (err) {
    failures.push({ item, error: err });
  }
}
if (failures.length) logger.warn({ failures }, 'Batch completed with errors');
```
