# Stack Negotiation — Detailed Process

## Overview

Stack negotiation transforms raw scanner findings into a user-confirmed stack.yml.
Every technology choice is classified into one of three decision tiers. The skill
adapts its prompting behavior based on the active profile's negotiation mode
(personal = confirm, work = full). Output is consumed by config-generator.

## Prerequisites

Before starting, verify:
1. `.ai/projects/[name]/dev/findings.md` exists with scan results
2. findings.md contains Workspace Context, MCP Servers, and Shared Config sections

If findings.md is missing, report error and suggest re-running project-scanner.

---

## Step 0: Initialize Trace (mandatory if tracing enabled)

Read `state.yml` and check `trace.enabled`. If `true`:

1. Create trace file: `.ai/projects/[name]/traces/stack-negotiation-{ISO-timestamp}.yml`
2. Write `_meta` block: schema `"trace"`, version `"1.1.0"`, skill, module, project, started_at, trace_mode
3. Initialize empty `steps: []`, `checkpoint_result: {}`, `quality_summary: {}`, `reflections: {}`

**Schema v1.1.0 — required fields per step:**
- `decision`, `reasoning`, `uncertainty` (always required)
- `observation` — what happened vs expected
- `improvement_idea` — actionable suggestion (if any)
- `design_decision` — lasting choice beyond this run (if any)

---

## Step 1: Load Inputs

```
Read .ai/projects/[name]/dev/findings.md
Extract:
  - Detected Frameworks (name, version, confidence, source)
  - Language, Package Manager
  - Architecture, API style
  - Testing, Linting, Formatting
  - Design Tooling (CSS approach, component library, icon library)
  - MCP Servers section (server names, types)
  - Workspace Context section (sibling project stacks)
  - Shared Config Packages section (detected shared configs)

Read active profile from .ai/profiles/{profile}.yml
Extract:
  - negotiation_mode: "confirm" | "full"
  - stack_defaults: { framework, css, component_lib, icons, ... }
  - shared_configs: [list of expected shared config packages]
```

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 2: Classify Decisions into Tiers

Classify every technology decision into one of three tiers:

### Always-Ask Tier
These are always prompted, regardless of profile or scanner confidence:
- **Framework** — runtime framework (Next.js, Nuxt, SvelteKit, Remix, etc.)
- **CSS approach** — Tailwind, CSS Modules, Styled Components, plain CSS, etc.
- **Component library** — shadcn/ui, Material UI, Ant Design, Radix, none, etc.
- **Icon library** — Lucide, Heroicons, Phosphor, none, etc.

### Ask-if-Ambiguous Tier
Only prompted when scanner found conflicting signals or nothing detected:
- **Auth provider** — NextAuth, Clerk, Auth0, Supabase Auth, custom, none
- **Database** — PostgreSQL, MySQL, SQLite, MongoDB, none
- **API style** — REST, GraphQL, tRPC, gRPC, mixed

Ambiguity triggers:
- Scanner found multiple candidates for the same role
- Scanner detected nothing (no signal at all)
- Scanner confidence is "low" for the detection

### Silent Tier
Applied automatically from profile defaults or scanner detections:
- **Linting** — ESLint config, rules
- **Formatting** — Prettier config
- **tsconfig** — TypeScript configuration
- **Editor config** — .editorconfig settings

Silent tier exceptions (surface to user):
- Conflict between scanner detection and profile default
- Monorepo with shared config that conflicts with local config
- Scanner found multiple conflicting configs

**Save classification to findings.md (2-Action Rule checkpoint).**

## Step 3: Negotiate Always-Ask Items

For each always-ask item, behavior depends on profile mode:

### Personal Profile ("confirm" mode)
```
Framework: Next.js 15 (profile default)
Use this? [Y/n]:
```
If user confirms → log decision with source: "profile_default"
If user changes → log decision with source: "user_choice"

### Work Profile ("full" mode)
```
Framework Selection:
  Scanner detected: Next.js 15 (from package.json, confidence: high)
  Profile default: Next.js 15
  Workspace: 2 other projects use Next.js 15

  Use Next.js 15? [Y/n/other]:
```
Present all available signals. If user picks "other", ask for their choice.

### For each always-ask item, present:
1. **Scanner detection** (if any) — what was found and confidence level
2. **Profile default** (if any) — what the profile recommends
3. **Workspace context** (if any) — what sibling projects use
4. Prompt for confirmation or override

Record each decision with:
```yaml
- item: "framework"
  value: "next.js"
  version: "15"
  source: "profile_default"  # or "user_choice", "scanner_detection", "workspace_match"
  confirmed_by: "user"
```

**Save to findings.md after every 2 confirmations (2-Action Rule).**

## Step 4: Negotiate Ask-if-Ambiguous Items

For each ask-if-ambiguous item, check if prompting is needed:

### Skip (no prompt needed)
- Scanner found exactly one candidate with high confidence
- No conflicting signals

When skipping, log:
```yaml
- item: "database"
  value: "postgresql"
  source: "scanner_detection"
  confirmed_by: "auto"
  reason: "Single high-confidence detection, no conflicts"
```

### Prompt (ambiguity detected)
```
Database:
  Scanner found conflicting signals:
    - Prisma config points to PostgreSQL
    - .env has MONGODB_URI defined
  Which database does this project use?
    1. PostgreSQL (via Prisma)
    2. MongoDB
    3. Both
    4. Other (specify)
  Your choice:
```

### Prompt (nothing detected)
```
API Style:
  No API style detected by scanner.
  What API style does this project use?
    1. REST
    2. GraphQL
    3. tRPC
    4. gRPC
    5. Mixed
    6. None / Not applicable
  Your choice:
```

**Save to findings.md after resolving ambiguities (2-Action Rule checkpoint).**

## Step 5: Apply Silent Tier Defaults

For each silent tier item:

1. Check if scanner detected a value
2. Check if profile has a default
3. Check for shared config packages

### Normal case (no conflicts)
Apply the value silently. Log:
```yaml
- item: "linting"
  value: "eslint"
  config: "@repo/eslint-config"  # if shared config
  source: "silent_default"
  confirmed_by: "auto"
```

### Conflict case (surface to user)
```
Linting Conflict:
  Scanner detected: ESLint with local .eslintrc.js
  Shared config found: @repo/eslint-config in packages/eslint-config/
  Profile expects: @repo/eslint-config

  Recommendation: Extend shared config (don't duplicate)
  Use shared config @repo/eslint-config? [Y/n]:
```

### Monorepo shared config rule
When a shared config package is detected:
- Always recommend extending it (`extends: ["@repo/eslint-config"]`)
- Never recommend duplicating or editing the shared package
- If local config exists alongside shared config, recommend migrating to extends

**Save to findings.md after Step 5 (2-Action Rule checkpoint).**

## Step 6: Surface MCP Recommendations

Read the MCP Servers section from findings.md. For each detected MCP server,
check if it's relevant to the confirmed stack:

```
MCP Recommendations:
  MCP server 'neon' detected — use Neon Postgres for database? [Y/recommendation only]
  MCP server 'supabase' detected — use Supabase for auth + database? [Y/recommendation only]
```

Rules:
- Present as recommendations, never force
- If user declines, log but don't remove the MCP server from config
- Map MCP servers to stack decisions where relevant:
  - neon → database: postgresql (Neon)
  - supabase → auth: supabase, database: postgresql (Supabase)
  - planetscale → database: mysql (PlanetScale)
  - firebase → auth: firebase, database: firestore

If no MCP servers found, log "No MCP servers detected" and continue.

**Save to findings.md after Step 6 (2-Action Rule checkpoint).**

## Step 7: Surface Workspace Context

Read the Workspace Context section from findings.md. For each technology
used by sibling projects, check if it's relevant:

```
Workspace Consistency:
  Other projects in this workspace use:
    - Next.js 15 (3 projects)
    - Tailwind CSS (3 projects)
    - PostgreSQL (2 projects)

  Your current selections already match workspace conventions.
```

Or if there's a mismatch:
```
Workspace Consistency:
  Note: You selected Vue.js, but 3 other projects use Next.js 15.
  This is fine — just flagging for awareness. Keep Vue.js? [Y/n]:
```

Rules:
- Informational only — never force consistency
- Only flag mismatches for always-ask and ask-if-ambiguous tier items
- Don't flag silent tier mismatches unless they cause build issues

## Step 8: Validate Shared Configs

Read the Shared Config Packages section from findings.md. Cross-reference
with profile expectations:

### Profile lists shared configs not found by scanner
```
Warning: Profile expects shared config @repo/tsconfig but scanner didn't find it.
  Options:
    1. Create it (will be scaffolded by config-generator)
    2. Skip — use local config instead
    3. Update profile to remove this expectation
  Your choice:
```

### Scanner found shared configs not in profile
```
Found shared config package: @repo/eslint-config
  Not listed in your profile. Add to profile for future projects? [Y/n]:
```

### Shared config rule enforcement
For every confirmed shared config:
- Log: `extends: "@repo/{config-name}"` in stack.yml
- Flag: "config-generator will scaffold with extends, not duplicate"
- Rule: "Never edit packages in packages/{shared-config}/ — extend only"

**Save to findings.md after Step 8 (2-Action Rule checkpoint).**

## Step 9: Generate stack.yml

Write the confirmed stack to `.ai/projects/[name]/dev/stack.yml`:

```yaml
meta:
  project_name: "[name]"
  profile: "[profile name]"
  negotiation_mode: "confirm"  # or "full"
  created_at: "[ISO8601]"
  negotiated_by: "stack-negotiation v1.0.0"

stack:
  # Always-ask tier (all user-confirmed)
  framework:
    value: "next.js"
    version: "15"
    source: "profile_default"
    confirmed_by: "user"
  css:
    value: "tailwind"
    version: "4"
    source: "user_choice"
    confirmed_by: "user"
  component_library:
    value: "shadcn/ui"
    source: "scanner_detection"
    confirmed_by: "user"
  icon_library:
    value: "lucide"
    source: "profile_default"
    confirmed_by: "user"

  # Ask-if-ambiguous tier
  auth_provider:
    value: "clerk"
    source: "scanner_detection"
    confirmed_by: "auto"
    reason: "Single high-confidence detection"
  database:
    value: "postgresql"
    source: "user_choice"
    confirmed_by: "user"
    mcp_recommendation: "neon"
  api_style:
    value: "rest"
    source: "scanner_detection"
    confirmed_by: "auto"

  # Silent tier
  linting:
    value: "eslint"
    config: "@repo/eslint-config"
    source: "silent_default"
    confirmed_by: "auto"
    extends_shared: true
  formatting:
    value: "prettier"
    config: "@repo/prettier-config"
    source: "silent_default"
    confirmed_by: "auto"
    extends_shared: true
  tsconfig:
    value: "typescript"
    config: "@repo/tsconfig"
    source: "silent_default"
    confirmed_by: "auto"
    extends_shared: true

workspace_context:
  sibling_matches: ["next.js", "tailwind", "postgresql"]
  mismatches: []
  mcp_servers_available: ["neon", "supabase"]

shared_configs:
  detected: ["@repo/eslint-config", "@repo/prettier-config", "@repo/tsconfig"]
  rule: "extend_only"
  note: "Never edit shared packages — extend in local configs"
```

## Step 10: Present Final Summary and Confirm

Present the complete stack for final confirmation:

```
## Confirmed Stack

**Framework:** Next.js 15 (profile default)
**CSS:** Tailwind CSS 4 (user choice)
**Components:** shadcn/ui (scanner detection)
**Icons:** Lucide (profile default)

**Auth:** Clerk (auto — high confidence detection)
**Database:** PostgreSQL via Neon (user choice + MCP recommendation)
**API:** REST (auto — scanner detection)

**Tooling:** ESLint + Prettier + TypeScript (shared configs from @repo/*)

**Workspace:** Matches 3 sibling projects
**MCP:** neon, supabase available

Stack looks good? [Y/n]:
```

Wait for explicit user confirmation.

If user wants changes, go back to the relevant tier step and re-negotiate.

Once confirmed, save final state to findings.md:
```markdown
## Stack Negotiation — Final
- Status: confirmed
- Stack path: .ai/projects/[name]/dev/stack.yml
- Decisions: [count] total ([always-ask count] user-confirmed, [ambiguous count] auto/user, [silent count] auto)
- Confirmed at: [timestamp]
```

## Error Handling

1. **Findings not found:** Log to state.yml errors. Suggest re-running project-scanner.
2. **Profile not found:** Proceed without profile defaults. Treat all items as "full" negotiation.
3. **Conflicting user input:** Ask for clarification. Never assume.
4. **Before retrying:** Check state.yml errors array. Never repeat a failed approach.

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only stack.yml and findings.md updates
2. Commit: `[plan_name]: stack-negotiation [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
- stack.yml exists and is valid YAML
- All always-ask items have `confirmed_by: "user"`
- Every decision has a `source` field
- MCP recommendations section present (servers listed or "none found")
- workspace_context section present

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
- Decision sources are plausible (scanner_detection items actually in findings.md)
- No contradictions (e.g., database: none but MCP neon accepted)
- Shared config extends are valid (packages actually exist)
- Workspace mismatches are acknowledged, not silently ignored

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.

---

## Trace Finalization (mandatory if tracing enabled)

Before completing, verify your trace file has:
1. All steps recorded (written every 2 steps per the 2-Action Rule)
2. `checkpoint_result` with pass/fail status
3. `quality_summary` with avg_uncertainty and recommendation
4. `reflections` section with at least one observation (REQUIRED — Stop hook enforces)
5. Step-level `observation`, `improvement_idea`, or `design_decision` where applicable
