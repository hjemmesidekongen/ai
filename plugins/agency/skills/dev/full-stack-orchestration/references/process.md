# Full-Stack Orchestration Process

Complete 9-step specification for end-to-end feature development.

## Behavioral rules

1. Execute steps in order. Do not skip, reorder, or merge steps.
2. Write output files. Each step produces its numbered `.full-stack-feature/NN-*.md` file before the next step begins. Read from prior step files — do not rely on context memory.
3. Stop at phase checkpoints. Present results and wait for explicit user approval.
4. Halt on failure. If any step fails, stop and present the error with options.
5. Use agency agents. Map to existing agency agents (software-architect, backend-worker, frontend-worker, qa-lead, devops, documentation-specialist).

## Pre-flight checks

### Check for existing session

If `.full-stack-feature/state.json` exists:
- `status: "in_progress"` → display current step, ask: Resume / Start fresh (archives existing)
- `status: "complete"` → ask whether to archive and start fresh

### Initialize state

```json
{
  "feature": "<description>",
  "status": "in_progress",
  "stack": "auto-detect",
  "api_style": "rest",
  "complexity": "medium",
  "current_step": 1,
  "current_phase": 1,
  "completed_steps": [],
  "files_created": [],
  "started_at": "ISO_TIMESTAMP",
  "last_updated": "ISO_TIMESTAMP"
}
```

Auto-detect stack from project-scanner output or `.ai/projects/*/stack.yml`.

---

## Phase 1: Architecture & Design (Steps 1-3)

### Step 1: Requirements gathering

Interactive Q&A — ask one question at a time:

1. **Problem statement**: What problem does this solve? Who is the user?
2. **Acceptance criteria**: Key criteria — when is this feature done?
3. **Scope boundaries**: What is explicitly out of scope?
4. **Technical constraints**: Existing conventions, latency requirements, auth system?
5. **Stack confirmation**: Confirm detected stack. Any changes?
6. **Dependencies**: Does this affect other features or services?

**Output**: `.full-stack-feature/01-requirements.md`

Structure: Problem Statement, Acceptance Criteria (checkboxes), In/Out of Scope, Technical Constraints, Technology Stack, Dependencies, Configuration (stack, API style, complexity).

### Step 2: Database & data model design

**Agent**: `agency:dev:software-architect`

**Input**: Read `01-requirements.md`

**Deliverables**:
1. Entity relationship design — tables, relationships, cardinality
2. Schema definitions — column types, constraints, defaults, nullable fields
3. Indexing strategy — which columns, index types, composite indexes
4. Migration strategy — safe schema changes in production
5. Query patterns — expected read/write patterns and how schema supports them
6. Data access patterns — repository/DAO interface design

**Output**: `.full-stack-feature/02-database-design.md`

### Step 3: Backend & frontend architecture

**Agent**: `agency:dev:software-architect`

**Input**: Read `01-requirements.md` + `02-database-design.md`

**Deliverables**:

Backend:
1. API design — endpoints, request/response schemas, error handling, versioning
2. Service layer — business logic components, responsibilities, boundaries
3. Auth — how authentication/authorization applies to new endpoints
4. Integration points — connections to existing services

Frontend:
1. Component hierarchy — pages, containers, presentational components
2. State management — what state, where it lives, data flow
3. Routing — new routes, navigation structure, route guards
4. API integration — data fetching strategy, caching, optimistic updates

Cross-cutting:
1. Error handling — backend errors → API responses → frontend error states
2. Security — input validation, XSS, CSRF, data protection
3. Risk assessment — technical risks and mitigation

**Output**: `.full-stack-feature/03-architecture.md`

---

### Phase Checkpoint 1 — User approval required

Present summary of database design and architecture. Ask:

```
Architecture and database design complete. Review:
- .full-stack-feature/02-database-design.md
- .full-stack-feature/03-architecture.md

1. Approve — proceed to implementation
2. Request changes — specify adjustments
3. Pause — save progress and stop
```

Do NOT proceed until user approves. On changes: revise and re-checkpoint.

---

## Phase 2: Implementation (Steps 4-7)

### Step 4: Database implementation

**Agent**: `agency:dev:backend-worker` (senior tier)

**Input**: `01-requirements.md` + `02-database-design.md`

**Tasks**:
1. Create migration scripts for schema changes
2. Implement models/entities matching schema design
3. Implement repository/data access layer
4. Add database-level validation constraints
5. Optimize queries with indexes as designed
6. Follow project's existing ORM and migration patterns

**Output**: `.full-stack-feature/04-database-impl.md` (summary of files created/modified)

### Step 5: Backend implementation

**Agent**: `agency:dev:backend-worker` (senior tier)

**Input**: `01-requirements.md` + `03-architecture.md` + `04-database-impl.md`

**Tasks**:
1. Implement API endpoints as designed
2. Implement business logic in service layer
3. Wire up data access layer
4. Add input validation, error handling, proper status codes
5. Implement auth middleware as designed
6. Add structured logging and observability
7. Follow project's existing code patterns

**Output**: `.full-stack-feature/05-backend-impl.md`

### Step 6: Frontend implementation

**Agent**: `agency:dev:frontend-worker` (senior tier)

**Input**: `01-requirements.md` + `03-architecture.md` + `05-backend-impl.md`

**Tasks**:
1. Build UI components following component hierarchy
2. Implement state management and data flow
3. Integrate with backend API endpoints
4. Implement form handling, validation, error states
5. Add loading states and optimistic updates
6. Ensure responsive design and accessibility (semantic HTML, ARIA, keyboard nav)
7. Follow project's existing frontend patterns

If the feature has no frontend component, skip — write a note in `06-frontend-impl.md`.

**Output**: `.full-stack-feature/06-frontend-impl.md`

### Step 7: Testing & validation (parallel)

Launch three agents in parallel:

**7a. Test suite** — Agent: `agency:dev:qa-lead`
- Unit tests for all new backend functions
- Integration tests for API endpoints
- Database tests for migrations and queries
- Frontend component tests
- Cover: happy path, edge cases, error handling, boundary conditions
- Target 80%+ coverage for new code

**7b. Security review** — Agent: `claude-core:security-auditor`
- OWASP Top 10 review
- Auth/authz flaws, input validation gaps
- SQL injection, XSS/CSRF vulnerabilities
- Data protection issues, dependency vulnerabilities

**7c. Performance review** — Agent: `agency:dev:software-architect`
- N+1 queries, missing indexes, unoptimized queries
- Memory leaks, missing caching opportunities
- Large payloads, slow rendering paths
- Bundle size concerns, unnecessary re-renders

**Output**: `.full-stack-feature/07-testing.md` (consolidated: test suite summary, security findings by severity, performance findings by impact, action items)

If critical/high severity findings exist, address them before proceeding.

---

### Phase Checkpoint 2 — User approval required

```
Testing and validation complete. Review .full-stack-feature/07-testing.md

Test coverage: [summary]
Security findings: [X critical, Y high, Z medium]
Performance findings: [X critical, Y high, Z medium]

1. Approve — proceed to deployment & documentation
2. Request changes — specify what to fix
3. Pause — save progress and stop
```

---

## Phase 3: Delivery (Steps 8-9)

### Step 8: Deployment & infrastructure

**Agent**: `agency:dev:devops`

**Input**: `03-architecture.md` + `07-testing.md`

**Tasks**:
1. Create/update CI/CD pipeline configuration
2. Add database migration steps to deployment pipeline
3. Feature flag configuration for gradual rollout
4. Health checks and readiness probes for new endpoints
5. Monitoring alerts for key metrics (error rate, latency, throughput)
6. Deployment runbook with rollback steps (including DB rollback)

**Output**: `.full-stack-feature/08-deployment.md`

### Step 9: Documentation & handoff

**Agent**: `agency:dev:documentation-specialist`

**Input**: All previous `.full-stack-feature/*.md` files

**Tasks**:
1. API documentation for new endpoints (request/response examples)
2. Database schema change documentation and migration notes
3. User-facing documentation if applicable
4. Architecture decision record (ADR) for key design choices
5. Handoff summary: what was built, how to test, known limitations

**Output**: `.full-stack-feature/09-documentation.md`

---

## Completion

Update `state.json`:
- `status`: `"complete"`
- `last_updated`: current timestamp

Present final summary with all 9 output files listed and next steps:
1. Review all generated code and documentation
2. Run the full test suite
3. Create a pull request
4. Deploy using the runbook in `08-deployment.md`

## Agent mapping

| Step | Source agent type | Agency agent |
|------|------------------|--------------|
| 2, 3 | general-purpose | software-architect |
| 4, 5 | general-purpose | backend-worker (senior) |
| 6 | general-purpose | frontend-worker (senior) |
| 7a | test-automator | qa-lead |
| 7b | security-auditor | security-auditor (claude-core) |
| 7c | performance-engineer | software-architect |
| 8 | deployment-engineer | devops |
| 9 | general-purpose | documentation-specialist |
