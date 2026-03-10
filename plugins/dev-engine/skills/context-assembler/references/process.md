# Context Assembler — Process Reference

## Context Sources

| Source | What it provides | Required |
|--------|-----------------|----------|
| Active task (decomposed subtask) | Description, acceptance criteria, file scope | Yes |
| Project map (.ai/project-map.yml) | Tech stack, module boundaries, architecture | No (degrades gracefully) |
| Knowledge skills (SKILL.md) | Framework patterns, anti-patterns, best practices | No |
| File contents (read scope) | Actual source code the agent will modify | Yes (if file scope defined) |

## Budget Algorithm

Default ceiling: 8,000 tokens per context package. Allocation by priority:

1. **Task section** (priority 1, max 1,500 tokens): Task description, acceptance criteria, parent task context if subtask. Never trimmed.
2. **File contents** (priority 2, max 3,000 tokens): Read files from `file_scope.read` and `file_scope.write`. Truncate large files to first 200 lines + last 50 lines.
3. **Project map excerpt** (priority 3, max 2,000 tokens): Only modules relevant to the subtask's file scope. Full map is never included.
4. **Knowledge skill summaries** (priority 4, max 1,500 tokens): SKILL.md body only (not frontmatter). Selected by tech stack tag match.

When total exceeds ceiling:
1. Trim knowledge skills to just their "## When to trigger" + first paragraph
2. Reduce project map to module names only (drop diagram)
3. Reduce file contents to function signatures only
4. Never drop the task section

## Tech Stack Matching

Match knowledge skills to the context by comparing `project-map.yml` stack tags against skill names and triggers:

```
project-map.stack.frameworks = ["next.js"]
→ match skills: nextjs-app-router, react-patterns, typescript-patterns
→ skip: prisma-patterns (no database in this subtask's scope)
```

Only include skills that match the subtask's file scope modules, not all project-level matches.

## Context Package Schema

```yaml
# .ai/tasks/context/<task-id>-<subtask-id>.yml
task_id: "TSK-001"
subtask_id: "TSK-001-03"
assembled_at: "2026-03-10T14:00:00Z"
token_estimate: 7200
budget_ceiling: 8000
map_available: true

task:
  title: "Add JWT middleware to protected routes"
  description: |
    Create Express middleware that validates JWT tokens
    and attaches user context to req.user.
  acceptance_criteria:
    - "Middleware rejects expired tokens with 401"
    - "Valid tokens populate req.user with id and email"
    - "Public routes bypass the middleware"
  file_scope:
    write: ["src/middleware/auth.ts"]
    read: ["src/types/user.ts", "src/config/jwt.ts"]

project_context:
  modules_in_scope: ["api"]
  framework: "express"
  language: "typescript"

files:
  - path: "src/types/user.ts"
    content: "..." # truncated to budget
  - path: "src/config/jwt.ts"
    content: "..."

knowledge:
  - skill: "typescript-patterns"
    excerpt: "..." # SKILL.md body, trimmed to budget
  - skill: "api-security"
    excerpt: "..."
```

## Caching

Context packages are written to disk and reused if:
- The subtask revision has not changed
- The project map mtime is within 24 hours
- No knowledge skills have been updated since assembly

Cache key: `<task-id>-<subtask-id>-<subtask-revision>-<map-mtime>`

## Anti-patterns

- Never dump the entire project map into every agent's context
- Never include knowledge skills that don't match the subtask's tech scope
- Never include `.env`, credentials, or secrets in the context package
- Never exceed the budget ceiling — trim, don't ignore the limit
- Never assemble context for a parent task — always use the decomposed subtask
- Never include file contents from outside the subtask's declared file scope
