# Knowledge Initializer — Detailed Process

## Overview

The knowledge initializer transforms confirmed project config and source analysis
into structured knowledge files that agents consume during builds. It produces
three files: architecture.md (module boundaries and data flow), patterns.yml
(design patterns detected in code), and conventions.yml (naming and organization
patterns). All entries start as `candidate` maturity and are promoted through
subsequent scans.

## Prerequisites

Before starting, verify:
1. `~/.claude/dev/[project-name]/dev-config.yml` exists with confirmed config
2. If dev-config.yml is missing, report error and suggest re-running config-generator
3. Read `structure.key_directories` — if empty, use `structure.src_root` as fallback

## Step 1: Load Project Config

```
Read ~/.claude/dev/[project-name]/dev-config.yml
Extract:
  - structure.src_root → where source code lives
  - structure.key_directories → directories to analyze
  - structure.entry_points → application entry points
  - frameworks.runtime → runtime frameworks (Next.js, Express, etc.)
  - frameworks.database → database frameworks (Prisma, Drizzle, etc.)
  - conventions.language → primary language
  - conventions.style.state_management → state management library
```

Also read `~/.claude/dev/[project-name]/findings.md` for any additional
context from the scanning phase.

**Save to findings.md after this step (2-Action Rule checkpoint).**

## Step 2: Analyze Module Boundaries

For each directory in `structure.key_directories`:

1. List files in the directory (Glob for `*.ts`, `*.tsx`, `*.js`, `*.jsx`, or
   language-appropriate extensions)
2. Read 2-3 representative files (prefer index/barrel files, entry points)
3. Extract import statements to map dependencies between directories
4. Classify the directory's responsibility based on:
   - Directory name (e.g., `components/` → UI, `api/` → API handlers)
   - File contents (exports, React components, route handlers, etc.)
   - Import patterns (what it imports from, what imports it)

Build an import graph:
```
module_graph = {}
for each directory:
  module_graph[dir] = {
    purpose: "classified responsibility",
    imports_from: [list of other directories],
    imported_by: [list of directories that import from this one],
    external_deps: [list of npm packages imported directly]
  }
```

**Save module graph to findings.md after every 2 directories analyzed (2-Action Rule).**

## Step 3: Map Data Flow

From the import graph, identify data flow patterns:

1. **Entry points** → trace the startup path (main → router → handlers)
2. **Request flow** (for web apps): route → middleware → handler → service → database
3. **State flow** (for frontend): store → actions → components → effects
4. **Event flow** (for event-driven): producer → queue/emitter → consumer → handler

For each flow:
- Note the direction (unidirectional, bidirectional, circular)
- Identify external boundaries (API calls, database queries, file I/O)
- Flag any circular dependencies as warnings

## Step 4: Generate architecture.md

Create `~/.claude/dev/[project-name]/knowledge/architecture.md`:

```markdown
---
tags: [architecture, overview]
maturity: candidate
created_at: "[ISO8601]"
updated_at: "[ISO8601]"
source: init-scan
hash: "[SHA-256 of content below frontmatter]"
entries:
  - fact: "Project architecture: [pattern]"
    confidence: high
    evidence: "dev-config.yml architecture section"
---

# Architecture Overview

## Module Boundary Diagram

```mermaid
graph TD
  [Generate mermaid diagram from module_graph]
  [Each directory is a node]
  [Arrows show import direction]
  [External deps shown as separate shape]
```

## Module Descriptions

### [directory-name]
- **Purpose:** [classified responsibility]
- **Key files:** [2-3 most important files]
- **Imports from:** [list of internal dependencies]
- **External deps:** [list of npm packages]

[Repeat for each key directory]

## External Integrations

[List APIs, databases, third-party services identified from imports]

## Data Flow

[Describe the primary data flow pattern identified in Step 3]
```

**The mermaid diagram must use valid mermaid syntax.** Common node types:
- Rectangles for internal modules: `A[Module Name]`
- Rounded for entry points: `A(Entry Point)`
- Database shape: `A[(Database)]`
- External service: `A{{External API}}`

## Step 5: Detect Design Patterns

Analyze source code for common patterns:

**Repository Pattern:**
- Files named `*Repository*`, `*Repo*`
- Classes/functions that abstract data access (findAll, findById, create, update)
- Evidence: file path and method signatures

**Service Layer:**
- Files named `*Service*`, `*UseCase*`
- Business logic separated from data access and controllers
- Evidence: file path, imports from repository layer

**Middleware Chain:**
- Files in middleware/ directory
- Express/Hono/Fastify middleware signatures
- Evidence: file path, function signatures

**Factory Pattern:**
- Functions that create and return configured objects
- Named `create*`, `make*`, `build*`
- Evidence: function names, return types

**Observer/Event Pattern:**
- EventEmitter usage, pub/sub patterns
- Files named `*Listener*`, `*Handler*`, `*Subscriber*`
- Evidence: event registration code

**State Management (frontend):**
- Check `conventions.style.state_management` from dev-config.yml
- Look for store configuration, action creators, selectors
- Map which components connect to which state slices

**Error Handling:**
- Custom error classes (extends Error)
- Error boundary components (React)
- Global error handlers (middleware, try/catch patterns)
- Evidence: file paths, class definitions

**Save to findings.md after every 2 pattern detection rounds (2-Action Rule).**

## Step 6: Generate patterns.yml

Create `~/.claude/dev/[project-name]/knowledge/patterns.yml`:

```yaml
---
tags: [patterns, architecture]
maturity: candidate
created_at: "[ISO8601]"
updated_at: "[ISO8601]"
source: init-scan
hash: "[SHA-256 of content below frontmatter]"
entries:
  - fact: "[Pattern name] pattern detected in [directory]"
    confidence: "[high/medium/low]"
    evidence: "[file paths, function signatures]"
    related_tags: ["[relevant tags]"]

  # Repeat for each detected pattern
```

**Confidence levels:**
- **High:** Pattern is explicit (named files, clear structure, multiple instances)
- **Medium:** Pattern is likely (naming suggests it, but structure is informal)
- **Low:** Pattern is possible (single instance, ambiguous indicators)

## Step 7: Detect Conventions

Analyze source code for naming and organization patterns:

**Naming Conventions:**
- Check 5+ files for variable/function naming: camelCase vs snake_case
- Check component naming: PascalCase components, lowercase utilities
- Check file naming: kebab-case, camelCase, PascalCase files
- Evidence: representative file names and variable names

**File Organization:**
- By feature: `features/auth/`, `features/dashboard/`
- By type: `components/`, `hooks/`, `utils/`
- Mixed: feature directories with type subdirectories
- Evidence: directory structure

**Import Ordering:**
- Check 3-5 files for consistent import ordering
- Common pattern: external packages → internal aliases → relative imports
- Look for import sorting tools (eslint-plugin-import, @trivago/prettier-plugin-sort-imports)
- Evidence: import blocks from representative files

**Barrel Exports:**
- Check for index.ts/index.js files that re-export from subdirectories
- Note whether the project uses barrel exports consistently
- Evidence: index file contents

**Save to findings.md after convention detection (2-Action Rule checkpoint).**

## Step 8: Generate conventions.yml

Create `~/.claude/dev/[project-name]/knowledge/conventions.yml`:

```yaml
---
tags: [conventions, style]
maturity: candidate
created_at: "[ISO8601]"
updated_at: "[ISO8601]"
source: init-scan
hash: "[SHA-256 of content below frontmatter]"
entries:
  - fact: "Variable naming uses [camelCase/snake_case]"
    confidence: "[high/medium/low]"
    evidence: "[sample files checked]"
    related_tags: ["style"]

  - fact: "File naming uses [kebab-case/camelCase/PascalCase]"
    confidence: "[high/medium/low]"
    evidence: "[sample directory listing]"
    related_tags: ["style"]

  - fact: "Files organized by [feature/type/mixed]"
    confidence: "[high/medium/low]"
    evidence: "[directory structure]"
    related_tags: ["architecture"]

  - fact: "Import ordering: [pattern]"
    confidence: "[high/medium/low]"
    evidence: "[sample files checked]"
    related_tags: ["style"]

  # Additional conventions as detected
```

## Step 9: Compute Content Hashes and Finalize

For each knowledge file:

1. Read the file content below the YAML frontmatter
2. Compute SHA-256 hash of the content
3. Set the `hash` field in frontmatter to the computed value

For tracked source files:

1. For each entry point in `dev-config.yml` `structure.entry_points`
2. For each knowledge file in `knowledge/`
3. Compute SHA-256 hash
4. Build `file_hashes` array: `[{path: "relative/path", hash: "sha256"}]`

## Step 10: Update dev-config.yml Scan Section

Update the `scan` section in `~/.claude/dev/[project-name]/dev-config.yml`:

```yaml
scan:
  last_scan_at: "[current ISO8601 timestamp]"
  file_hashes:
    - path: "knowledge/architecture.md"
      hash: "[SHA-256]"
    - path: "knowledge/patterns.yml"
      hash: "[SHA-256]"
    - path: "knowledge/conventions.yml"
      hash: "[SHA-256]"
    # Plus entry point hashes
  files_tracked: [count of all hashed files]
  scan_duration_ms: [approximate duration]
```

**Save final state to findings.md (2-Action Rule checkpoint).**

## Error Handling

When errors occur during knowledge initialization:

1. **File read failures:** Log to state.yml errors array with the path and error.
   Skip the file and continue analysis. Note the gap in findings.md.

2. **Circular imports detected:** Log as a finding (not an error). Record in
   architecture.md as a warning node in the mermaid diagram. Do not attempt
   to resolve — just document.

3. **Ambiguous patterns:** When a pattern could be classified multiple ways,
   record with `confidence: low` and note the ambiguity in the evidence field.

4. **Before retrying:** Always check state.yml errors array for previous failed
   attempts. Never repeat the same approach.

## Commit Protocol

**Subagent mode** (dispatched via Task()):
1. Stage only knowledge files and dev-config.yml updates
2. Commit: `[plan_name]: knowledge-initializer [task_id]`
3. Report commit SHA in task_complete

**Inline mode:** Commit after verification passes with descriptive message.

## Two-Stage Verification

**Stage 1 — Spec Compliance (Haiku):**
Run spec-compliance-reviewer. Checks:
- Knowledge files exist in `~/.claude/dev/[project-name]/knowledge/`
- All files have frontmatter with `tags` array (non-empty)
- All files have `maturity: candidate`
- architecture.md contains at least 1 ` ```mermaid ` block
- dev-config.yml `scan.last_scan_at` is a valid ISO 8601 timestamp
- dev-config.yml `scan.file_hashes` is non-empty

If FAIL: fix structural issues. Do NOT proceed to Stage 2.

**Stage 2 — Quality Review (Opus):**
Only after Stage 1 passes. Checks:
- Architecture diagram accurately reflects key_directories from dev-config.yml
- Pattern detection has reasonable confidence levels (not all high, not all low)
- Conventions match what's actually visible in the source code
- Knowledge entries are useful (not trivially obvious or overly generic)
- No near-duplicate entries (Jaccard similarity < 0.8)

If FAIL: address quality issues.
If PASS_WITH_NOTES: review notes, decide whether to address.
