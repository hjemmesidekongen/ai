---
name: nestjs-patterns
description: >
  NestJS modules, providers, guards, interceptors, pipes, and testing patterns.
  Module organization, request lifecycle, decorator patterns, and test strategy.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "nestjs"
  - "nest.js patterns"
  - "nestjs modules"
  - "nestjs guards"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "module_boundaries"
      verify: "Feature modules own their providers — no cross-module provider leakage"
      fail_action: "Audit module imports and move shared providers to a SharedModule"
    - name: "injectable_scope"
      verify: "Providers use DEFAULT scope unless request-scoped state is explicitly needed"
      fail_action: "Remove unnecessary REQUEST or TRANSIENT scopes — they break singleton assumptions"
    - name: "guard_order"
      verify: "Auth guard runs before role guard in the execution context chain"
      fail_action: "Reorder guards — AuthGuard must establish identity before RolesGuard checks permissions"
    - name: "pipe_placement"
      verify: "Validation pipes applied at controller or global level, not ad-hoc inside handlers"
      fail_action: "Move validation to pipes; handlers should receive already-validated data"
    - name: "test_isolation"
      verify: "Unit tests mock all providers; no real DB or HTTP calls in unit tests"
      fail_action: "Replace real providers with jest.fn() mocks or Test.createTestingModule overrides"
  on_fail: "NestJS structural issues found — fix before merging"
  on_pass: "NestJS patterns are sound"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for dev-engine"
---

# NestJS Patterns

NestJS is Angular-influenced — modules, DI, and decorators are the core model. Work with the framework's conventions; fighting them creates unmaintainable code.

## Module Organization

Feature modules own everything inside their boundary: controller, service, repository, DTOs. CoreModule handles app-wide singletons (config, logger, DB connection). SharedModule exports reusable utilities with no circular dependencies.

Keep `AppModule` thin — it imports feature modules and wires global middleware only.

## Request Lifecycle

Middleware → Guards → Interceptors (pre) → Pipes → Handler → Interceptors (post) → Exception Filters

Order matters. Guards run before pipes. Interceptors wrap the entire handler. Exception filters catch what escapes guards and handlers both.

## Decorator Patterns

Use custom decorators to extract repeated logic from handlers: `@CurrentUser()`, `@Roles()`, `@Public()`. Keep handlers thin — they should read like a spec, not an implementation.

Combine `@UseGuards()`, `@UseInterceptors()`, and `@UsePipes()` at the controller level when they apply to all routes. Route-level decorators only when behavior diverges.

## Testing Approach

Unit tests: `Test.createTestingModule()` with mocked providers. Mock at the service boundary, not inside services. Test one class per file.

E2E tests: `@nestjs/testing` with `supertest`. Spin up the full app, hit real endpoints, use a test DB or in-memory store. Cover auth flows and request validation end-to-end.

See `references/process.md` for module patterns, DI, guards, interceptors, pipes, exception filters, middleware, microservices basics, CQRS, and anti-patterns.
