# nestjs-patterns — Debugging Reference

## Common Debugging Scenarios

### 1. Circular dependency DI failure

**Symptom:** `Error: Nest cannot create the <ModuleName> instance. The module at index [x] of the <ParentModule> "imports" array is undefined.` or `Nest can't resolve dependencies of the <Service>`.

**Root cause:** Two modules or providers import each other, creating a cycle the DI container cannot resolve. Often introduced when ServiceA injects ServiceB and ServiceB injects ServiceA across module boundaries.

**Diagnosis:**
- Start the app with debug logging: `nest start --debug` — the DI resolution trace prints the full dependency chain before the error
- Search for the cycle by grepping mutual imports: check both modules' `imports` arrays and both services' constructor injections
- Use `madge --circular --extensions ts src/` to statically detect import cycles across the codebase
- If the error names a specific index (`index [2]`), count the imports array in that module — the item at that position is the broken link

**Fix pattern:**
- Apply `forwardRef(() => OtherModule)` in the `imports` array of one side of the cycle
- Apply `@Inject(forwardRef(() => OtherService))` in the constructor of one side
- Better long-term: extract the shared dependency into a third module that both import, breaking the cycle entirely

---

### 2. Guard/interceptor execution order

**Symptom:** A guard runs before expected, an interceptor doesn't see the modified request, or auth fails despite a valid token because a different guard rejected first.

**Root cause:** NestJS executes in a fixed pipeline: middleware -> guards -> interceptors (pre) -> pipes -> handler -> interceptors (post) -> exception filters. Within guards, global runs before controller-level, which runs before method-level.

**Diagnosis:**
- Add a `console.log` with the class name at the top of each guard's `canActivate()` and each interceptor's `intercept()`:
  ```typescript
  canActivate(context: ExecutionContext): boolean {
    console.log(`[GUARD] ${this.constructor.name} — ${context.getHandler().name}`);
    // ...
  }
  ```
- Fire a request and read the log output top-to-bottom — that is the actual execution order
- Check `app.module.ts` for `APP_GUARD` / `APP_INTERCEPTOR` providers — their registration order determines global execution order
- Check controller and method decorators — `@UseGuards(A, B)` executes A before B

**Fix pattern:**
- Reorder the arguments in `@UseGuards()` or `@UseInterceptors()` to match intended sequence
- If a guard depends on data set by an interceptor, that won't work — guards always run first. Move the data-setting logic to a middleware or an earlier guard instead

---

### 3. Middleware not firing

**Symptom:** Custom middleware function never executes — no log output, no request modification, no error. The route works but the middleware is invisible.

**Root cause:** Middleware is registered via `NestModule.configure()` and must be explicitly bound to routes. Unlike guards, it does not auto-apply. Common mistakes: wrong route pattern, forgetting to call `consumer.apply()`, or the module containing the middleware config is not imported.

**Diagnosis:**
- Add a log as the first line of the middleware's `use()` method:
  ```typescript
  use(req: Request, res: Response, next: NextFunction) {
    console.log(`[MW] ${this.constructor.name} hit: ${req.method} ${req.originalUrl}`);
    next();
  }
  ```
- Verify the module implementing `NestModule` is in the `imports` of `AppModule`
- Check the `configure()` method — `forRoutes('users')` matches `/users` but not `/api/users` if there's a global prefix. Use `forRoutes({ path: '*', method: RequestMethod.ALL })` temporarily to confirm the middleware can fire at all
- If using a global prefix via `app.setGlobalPrefix('api')`, middleware route patterns still match against the raw route without the prefix

**Fix pattern:**
- Correct the `forRoutes()` pattern to match actual route paths (without global prefix)
- For truly global middleware, use `app.use(new YourMiddleware().use)` in `main.ts` instead of module-level config

---

### 4. Testing module provider not found

**Symptom:** `Nest can't resolve dependencies of the <ServiceUnderTest> (?). Please make sure that the argument <DependencyName> at index [0] is available in the RootTestModule context.`

**Root cause:** `Test.createTestingModule()` builds an isolated DI container. Every dependency the service under test injects must be explicitly provided — either as a real class or a mock. The error message names the missing provider.

**Diagnosis:**
- Read the full error message — it names the exact missing provider and its position in the constructor
- Open the service under test and list every constructor parameter — each one needs a corresponding entry in the test module's `providers` array
- Check for injection tokens (`@Inject('CONFIG')`) vs class-based injection — tokens need `{ provide: 'CONFIG', useValue: {...} }` syntax
- Check if the dependency itself has further dependencies that also need mocking

**Fix pattern:**
```typescript
const module = await Test.createTestingModule({
  providers: [
    ServiceUnderTest,
    { provide: MissingDependency, useValue: { methodName: jest.fn() } },
  ],
}).compile();
```
- For services with many dependencies, use `@golevelup/ts-jest`'s `createMock<T>()` to auto-generate mocks:
  ```typescript
  { provide: MissingDependency, useValue: createMock<MissingDependency>() }
  ```

---

### 5. Request-scoped providers cascading scope

**Symptom:** Performance degrades as traffic increases. Response times grow non-linearly. Memory usage climbs steadily under load.

**Root cause:** Marking a provider as `@Injectable({ scope: Scope.REQUEST })` forces every provider that depends on it — and their dependents — to also become request-scoped. NestJS instantiates the entire chain per request instead of reusing singletons. One request-scoped provider deep in the graph can cascade scope to dozens of providers.

**Diagnosis:**
- Search for `Scope.REQUEST` and `Scope.TRANSIENT` across the codebase: `grep -r "Scope\." --include="*.ts" src/`
- Map the dependency chain: find every service that injects the request-scoped provider, then find what injects those, recursively
- Take heap snapshots before and after 100 requests using `--inspect`:
  ```bash
  node --inspect dist/main.js
  ```
  Open `chrome://inspect`, take snapshot, send 100 requests, take another snapshot, compare retained object counts for your provider classes
- Check NestJS startup logs with `Logger` level set to `debug` — it reports scope resolution

**Fix pattern:**
- Minimize request-scoped providers. If you only need the request object, inject it via `@Req()` in the controller and pass it explicitly rather than making the service request-scoped
- Use `REQUEST` injection token with `@Inject(REQUEST)` only in the controller layer, then pass needed values (user ID, tenant ID) as method arguments to singleton services
- If request scope is genuinely needed, keep it at the leaf of the dependency tree — never on a widely-imported utility service

## Debugging Tools

| Tool | When to use | Command |
|------|-------------|---------|
| NestJS debug mode | DI resolution failures, startup crashes | `nest start --debug` |
| Node inspector | Memory leaks, CPU profiling, heap snapshots | `node --inspect dist/main.js` then `chrome://inspect` |
| madge | Circular dependency detection (static) | `npx madge --circular --extensions ts src/` |
| NestJS logger | Runtime execution flow | `Logger.overrideLogger(['debug', 'verbose'])` in `main.ts` |
| ts-node REPL | Test DI wiring in isolation | `npx ts-node -e "import { NestFactory } from '@nestjs/core'; ..."` |

## Escalation

When framework-specific debugging doesn't resolve the issue, escalate to
the root-cause-debugging protocol (kronen) for systematic 4-phase investigation.
