# Config Generator — Detailed Process

## Overview

The config generator transforms project-scanner findings into a validated
dev-config.yml file. This is an interactive skill — every detection is
presented to the user for confirmation before being written. The output
file becomes the central contract that all downstream dev skills consume.

## Prerequisites

Before starting, verify:
1. `~/.claude/dev/[project-name]/findings.md` exists with scan results
2. If findings.md is missing or empty, report error and suggest re-running project-scanner

## Step 1: Load Scan Results

```
Read ~/.claude/dev/[project-name]/findings.md
Extract:
  - Detected Frameworks section → list of (name, version, confidence, source)
  - Language section → primary language
  - Package Manager section → manager name
  - Architecture section → pattern, monorepo, router, API style
  - Testing section → unit framework, e2e framework
  - Linting & Formatting section → linter, formatter
  - Source Structure section → entry points, key directories, component library, icon library, state management
  - Git Conventions section → commit pattern, branch pattern
  - Ambiguous Detections section → items needing user clarification
```

If any section is missing, note it — those fields will need to be asked directly.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 2: Initialize Config Structure

Create the dev-config.yml in memory following the schema at
`plugins/dev/resources/templates/dev-config-schema.yml`:

```yaml
meta:
  plugin_name: "dev"
  project_name: "[from findings or directory name]"
  project_root: "[absolute path to project root]"
  created_at: "[ISO8601 timestamp]"
  updated_at: "[ISO8601 timestamp]"
  version: "1.0"
  generated_by: "dev v1.0.0"

frameworks:
  runtime: []
  build: []
  testing: []
  database: []

conventions:
  language: ""
  package_manager: ""
  monorepo: false
  # ... remaining fields populated in subsequent steps

commands:
  build: ""
  dev: ""
  test: ""
  # ... remaining fields

structure:
  src_root: ""
  entry_points: []
  key_directories: []

scan:
  last_scan_at: "[ISO8601 timestamp]"
  file_hashes: []
  files_tracked: 0
  scan_duration_ms: 0
```

## Step 3: Confirm Frameworks (Interactive)

For each detected framework from findings.md, present to the user one at a time:

```
Detected [name] [version] (from [source], confidence: [level]).
Correct? [Y/n]
```

**If user confirms (Y or Enter):** Add to the appropriate frameworks array (runtime, build, testing, or database).

**If user corrects:** Ask what the correct value is, update the entry.

**If user says "not used":** Skip — do not add to config.

**Classify each framework into the correct array:**
- Runtime: Next.js, Nuxt, SvelteKit, Remix, Express, Fastify, Hono, Nest.js
- Build: Vite, Webpack, Turborepo, Nx, esbuild, tsup
- Testing: Jest, Vitest, Playwright, Cypress, Mocha
- Database: Prisma, Drizzle, TypeORM, Sequelize, Knex, Mongoose

**After every 2 confirmations, save confirmed frameworks to findings.md.**

## Step 4: Confirm Ambiguous Detections (Interactive)

If findings.md has an "Ambiguous Detections" section, present each item:

```
Ambiguous: [observation]
Possible interpretations: [list]
Which is correct? [options]
```

These often include:
- Multiple frameworks that could serve the same role
- Version ambiguity (range vs exact)
- Polyglot detection (multiple primary languages)

**Save to findings.md after resolving ambiguities (2-Action Rule checkpoint).**

## Step 5: Confirm Conventions (Interactive)

Present detected conventions one at a time, offering the detected value as default:

**Language:**
```
Primary language detected: [language]
Correct? [Y/n]
```

**Package manager:**
```
Package manager detected: [manager] (from [lock file])
Correct? [Y/n]
```

**Monorepo:**
```
Monorepo detected: [yes/no] [tool if applicable]
Correct? [Y/n]
```

**Architecture pattern:**
```
Architecture pattern: [monolith/microservices/modular-monolith/serverless]
Correct? [Y/n]
```

**API style:**
```
API style detected: [rest/graphql/trpc/grpc/mixed]
Correct? [Y/n]
```

**State management (if frontend project):**
```
State management detected: [name or none]
Correct? [Y/n]
```

**Save to findings.md after Step 5 (2-Action Rule checkpoint).**

## Step 6: Ask Non-Detectable Conventions (Interactive)

These conventions require user input — auto-detection provides suggestions only:

**Branch pattern:**
```
What's your branch naming pattern?
Detected from git log: [pattern or "no clear pattern"]
Suggestions: feature/<KEY>-<desc>, feat/<desc>, feature/<desc>
Your pattern:
```

**Commit format:**
```
What's your commit message format?
Detected from recent commits: [pattern or "no clear pattern"]
Suggestions: JIRA-KEY: description, feat: description, plain description
Your format:
```

**Coverage threshold:**
```
Target test coverage threshold?
Suggestion: 80% (industry standard)
Your threshold (0-100, or Enter for 80):
```

**Main branch:**
```
Default branch: [detected from git, usually "main" or "master"]
Correct? [Y/n]
```

**Linting & Formatting:**
```
Linter: [detected or none]
Formatter: [detected or none]
Correct? [Y/n]
```

**Save to findings.md after Step 6 (2-Action Rule checkpoint).**

## Step 7: Map Commands from package.json

Read package.json `scripts` and map to dev-config commands:

| Config Key | Look for scripts named | Fallback |
|-----------|----------------------|----------|
| `build` | build, build:prod | Ask user |
| `dev` | dev, start, serve | Ask user |
| `test` | test, test:unit | Ask user |
| `test_related` | test:related, test:changed | Construct from test framework if known |
| `lint` | lint, lint:check | Construct from linter (e.g., `npx eslint .`) |
| `format` | format, format:check | Construct from formatter (e.g., `npx prettier --check .`) |
| `typecheck` | typecheck, type-check, types | `npx tsc --noEmit` if TypeScript project |

**For each mapped command, present to user:**
```
Build command: [detected: "npm run build"]
Correct? [Y/n]
```

**For missing required commands (build, dev, test, lint), ask explicitly:**
```
No [type] command detected in package.json scripts.
What command runs your [type]? (or Enter to skip)
```

**Save to findings.md after Step 7 (2-Action Rule checkpoint).**

## Step 8: Populate Structure Section

From findings.md Source Structure section:

1. Set `src_root` to detected source root directory
2. Populate `entry_points` array from detected entry points
3. Populate `key_directories` array from detected directories
4. Set `component_library` from findings
5. Set `icon_library` from findings

Present structure summary to user:
```
Source root: [path]
Entry points:
  - [path] ([type])
Key directories:
  - [path]: [purpose]
Component library: [name or none]
Icon library: [name or none]

Correct? [Y/n]
```

## Step 9: Populate Scan Metadata

Set the `scan` section:
```yaml
scan:
  last_scan_at: "[current ISO8601 timestamp]"
  file_hashes: []  # populated by project-scanner on next run
  files_tracked: 0  # updated by delta-scanner
  scan_duration_ms: 0  # recorded by project-scanner
```

These values are placeholders — the actual scan metadata is populated by the
scanner skills during execution.

## Step 10: Write and Confirm

1. Write the completed dev-config.yml to `~/.claude/dev/[project-name]/dev-config.yml`

2. Present the full config summary to the user in a readable format:

```
## Config Summary

**Project:** [name]
**Language:** [language] | **Package Manager:** [manager]
**Architecture:** [pattern] | **API:** [style]
**Monorepo:** [yes/no] [tool]

### Frameworks
- Runtime: [list]
- Build: [list]
- Testing: [list]
- Database: [list]

### Conventions
- Branch: [pattern]
- Commit: [format]
- Linter: [tool] | Formatter: [tool]
- Coverage: [threshold]%

### Commands
- Build: [command]
- Dev: [command]
- Test: [command]
- Lint: [command]

### Structure
- Source root: [path]
- Entry points: [list]
- Key dirs: [count] directories mapped

Config looks good? [Y/n]
```

3. Wait for explicit user confirmation.

4. If user wants changes, go back to the relevant section and re-ask.

5. Once confirmed, save final state to findings.md:
```markdown
## Config Generation — Final
- Status: confirmed
- Config path: ~/.claude/dev/[project-name]/dev-config.yml
- Confirmed at: [timestamp]
```

## Error Handling

When errors occur during config generation:

1. **Findings not found:** Log to state.yml errors array. Report to user and
   suggest re-running project-scanner. Do not attempt to generate config
   without scan results.

2. **Schema validation failures:** If a value doesn't match the schema enum
   (e.g., unrecognized language), log the error, present the valid options
   to the user, and ask them to choose.

3. **Missing required fields after all questions:** Run through the checkpoint
   checks. For any failures, ask the user directly for the value.

4. **Before retrying:** Always check state.yml errors array for previous failed
   attempts. Never repeat the same approach.

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only dev-config.yml and findings.md updates
2. Commit: `[plan_name]: config-generator [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- dev-config.yml exists and is non-empty
- Contains required sections (meta, frameworks, conventions, commands)
- meta has all required fields (plugin_name, project_name, created_at, version)
- frameworks.runtime array exists
- conventions.language is populated with a valid value
- commands.build is populated

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Framework versions match what's actually in package.json
- Convention choices are consistent (e.g., TypeScript project has typecheck command)
- Commands are valid (not empty strings, use correct package manager prefix)
- Structure paths actually exist in the project
- No contradictions (e.g., monorepo: true but no monorepo tool)

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.
