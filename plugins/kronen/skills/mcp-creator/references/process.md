# MCP Creator — Full Reference

## Configuration methods

### Method 1: Dedicated .mcp.json (recommended)

Create `.mcp.json` at the plugin root directory. Each top-level key is a server name.

```json
{
  "database-tools": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "DB_URL": "${DB_URL}"
    }
  }
}
```

Benefits: clear separation, easier maintenance, better for multi-server plugins.

### Method 2: Inline in plugin.json

Add `mcpServers` field to `.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "mcpServers": {
    "plugin-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"]
    }
  }
}
```

Benefits: single file, good for simple single-server plugins.

### When to use which

| Scenario | Method |
|----------|--------|
| Multiple servers | `.mcp.json` |
| Single simple server | Either (`.mcp.json` preferred) |
| Server config changes often | `.mcp.json` (less manifest churn) |
| Minimal plugin | `mcpServers` in plugin.json |

## Server type configuration

### Required fields by type

| Type | Required | Optional |
|------|----------|----------|
| stdio | `command` | `args`, `env` |
| sse | `type: "sse"`, `url` | `headers` |
| http | `type: "http"`, `url` | `headers` |
| ws | `type: "ws"`, `url` | `headers` |

stdio servers have no `type` field — the absence of `type` implies stdio.

### stdio configuration

```json
{
  "my-server": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/custom-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "API_KEY": "${MY_API_KEY}",
      "LOG_LEVEL": "info"
    }
  }
}
```

### SSE configuration

```json
{
  "cloud-service": {
    "type": "sse",
    "url": "https://mcp.example.com/sse"
  }
}
```

### HTTP configuration

```json
{
  "rest-api": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}",
      "X-API-Version": "2024-01-01"
    }
  }
}
```

### WebSocket configuration

```json
{
  "realtime": {
    "type": "ws",
    "url": "wss://mcp.example.com/ws",
    "headers": {
      "Authorization": "Bearer ${TOKEN}"
    }
  }
}
```

## Environment variable expansion

All MCP configurations support `${VAR}` substitution.

### Built-in variables

| Variable | Expands to |
|----------|-----------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin directory (always use for portability) |
| `${CLAUDE_PROJECT_DIR}` | Project root directory |

### User environment variables

Variables from the user's shell environment:

```json
{
  "env": {
    "API_KEY": "${MY_API_KEY}",
    "DATABASE_URL": "${DB_URL}"
  }
}
```

Document all required environment variables in the plugin README.

## Tool naming convention

### Format

```
mcp__plugin_<plugin-name>_<server-name>__<tool-name>
```

### Example

- Plugin: `my-plugin`, Server: `database`, Tool: `query`
- Full name: `mcp__plugin_my-plugin_database__query`

### Discovering tool names

Run `/mcp` in Claude Code to see all registered servers, their tools, and full tool names.

## Using MCP tools in commands

Pre-allow specific MCP tools in command frontmatter:

```markdown
---
description: Search and create tasks
allowed-tools: [
  "mcp__plugin_asana_asana__asana_search_tasks",
  "mcp__plugin_asana_asana__asana_create_task"
]
---
```

Wildcards are supported but discouraged for security:

```markdown
allowed-tools: ["mcp__plugin_asana_asana__*"]
```

Pre-allow only the specific tools the command needs.

## Using MCP tools in agents

Agents can use MCP tools without pre-allowing them — document which tools the agent
typically uses in its system prompt:

```markdown
## Available Tools

This agent uses the following MCP tools:
- mcp__plugin_db_server__query — query database
- mcp__plugin_db_server__execute — run mutations
```

## Authentication patterns

### OAuth (SSE/HTTP — automatic)

No configuration needed. Claude Code handles the full OAuth 2.0 flow:
1. User attempts to use an MCP tool
2. Claude Code opens browser for OAuth consent
3. Tokens stored and refreshed automatically

```json
{
  "type": "sse",
  "url": "https://mcp.example.com/sse"
}
```

### Token-based (headers)

Static or environment-variable tokens in `headers`:

```json
{
  "type": "http",
  "url": "https://api.example.com/mcp",
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}"
  }
}
```

### Environment variables (stdio)

Pass credentials to the server process via `env`:

```json
{
  "command": "python",
  "args": ["-m", "mcp_server_db"],
  "env": {
    "DATABASE_URL": "${DATABASE_URL}",
    "DB_PASSWORD": "${DB_PASSWORD}"
  }
}
```

### Dynamic headers (headersHelper)

For tokens that expire or require signing, use a helper script:

```json
{
  "type": "sse",
  "url": "https://api.example.com",
  "headersHelper": "${CLAUDE_PLUGIN_ROOT}/scripts/get-headers.sh"
}
```

The script must output a JSON object of headers to stdout.

## Integration patterns

### Pattern 1: Simple tool wrapper

A command that validates input, calls one MCP tool, and confirms the result.
Best for single-action operations (create, update, delete).

### Pattern 2: Autonomous agent

An agent that chains multiple MCP tool calls without user interaction.
Best for multi-step workflows (analyze → transform → report).

### Pattern 3: Multi-server plugin

Combine servers of different types in one `.mcp.json`:

```json
{
  "local-db": {
    "command": "npx",
    "args": ["-y", "mcp-server-sqlite", "./data.db"]
  },
  "cloud-api": {
    "type": "sse",
    "url": "https://mcp.example.com/sse"
  },
  "internal-service": {
    "type": "http",
    "url": "https://api.internal.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

## Security

### HTTPS/WSS only

All remote MCP server URLs must use secure protocols:
- `https://` for SSE and HTTP servers
- `wss://` for WebSocket servers
- Never use `http://` or `ws://`

### No hardcoded tokens

Tokens, API keys, and passwords must reference environment variables via `${VAR}`,
never appear as literal values in configuration files.

### Permission scoping

Pre-allow only the specific MCP tools each command needs. Avoid wildcard
`allowed-tools` entries.

### allowedEnvVars

HTTP hooks that interact with MCP should limit `allowedEnvVars` to only the
variables they need — not broad access to the full environment.

### No secrets in committed files

- `.env` files in `.gitignore`
- Example configs use `${VAR}` placeholders, not real values
- README shows `export VAR="your-value-here"` patterns

## Testing

### Verify server connectivity

1. Configure MCP server in `.mcp.json`
2. Install/enable the plugin
3. Run `/mcp` to verify the server appears
4. Test a tool call from a command
5. Check `claude --debug` for connection issues

### Validation checklist

- [ ] MCP configuration is valid JSON (`python3 -m json.tool`)
- [ ] Server type has correct required fields (command or url)
- [ ] All paths use `${CLAUDE_PLUGIN_ROOT}` — no absolute paths
- [ ] URLs use HTTPS/WSS — no insecure protocols
- [ ] Environment variables referenced via `${VAR}` — no inline secrets
- [ ] Required env vars documented in README
- [ ] Tools appear in `/mcp` output
- [ ] Authentication works (OAuth flow or token headers)
- [ ] Tool calls succeed from commands
- [ ] Error cases handled gracefully

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Hardcoded absolute path | Breaks on other machines | Use `${CLAUDE_PLUGIN_ROOT}` |
| HTTP instead of HTTPS | Insecure, may be blocked | Switch to HTTPS/WSS |
| Inline secret in config | Credential leak in git | Use `${VAR}` reference |
| Missing `type` on SSE/HTTP/WS | Treated as stdio, fails | Add `"type": "sse"` (or http/ws) |
| Wildcard `allowed-tools` | Over-permissive commands | List specific tool names |
| Missing env var docs | Users can't configure | Document in README |
| stdout logging in stdio server | Corrupts MCP protocol | Log to stderr only |
| Forgetting `args` array format | Server won't start | Use array, not string |

## Implementation workflow

1. Choose server type based on use case (see SKILL.md table)
2. Create `.mcp.json` at plugin root (or add `mcpServers` to plugin.json)
3. Configure server with required fields per type
4. Use `${CLAUDE_PLUGIN_ROOT}` for all file references
5. Document required environment variables in README
6. Test locally with `/mcp` command
7. Pre-allow specific MCP tools in relevant commands
8. Configure authentication (OAuth, tokens, or env vars)
9. Test error cases (connection failures, auth errors, invalid params)
10. Run validation checklist above

## Tool annotations

Tool annotations are optional hints that tell Claude how a tool behaves, enabling safer agentic decisions.

### The four hints

| Hint | Type | Meaning |
|------|------|---------|
| `readOnlyHint` | boolean | Tool does not modify state (read-only) |
| `destructiveHint` | boolean | Tool may cause irreversible side effects (delete, overwrite) |
| `idempotentHint` | boolean | Calling the tool multiple times with the same args has the same effect |
| `openWorldHint` | boolean | Tool interacts with external/unbounded systems (web, filesystem, external APIs) |

### When to apply

- Mark all read-only tools with `readOnlyHint: true` — Claude can call these freely
- Mark delete/overwrite operations with `destructiveHint: true` — Claude will seek confirmation
- Mark PUT-style operations with `idempotentHint: true` — safe to retry on failure
- Mark tools touching external systems with `openWorldHint: true` — signals unpredictable output

### Python FastMCP example

```python
from mcp.server.fastmcp import FastMCP
mcp = FastMCP("my-server")

@mcp.tool(annotations={"readOnlyHint": True, "openWorldHint": False})
def get_user(user_id: str) -> dict:
    """Fetch a user record by ID."""
    ...

@mcp.tool(annotations={"destructiveHint": True, "idempotentHint": False})
def delete_record(record_id: str) -> bool:
    """Permanently delete a record."""
    ...
```

### Node MCP SDK example

```typescript
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "get_user",
      description: "Fetch a user record by ID",
      annotations: { readOnlyHint: true, openWorldHint: false },
      inputSchema: { type: "object", properties: { user_id: { type: "string" } } },
    },
    {
      name: "delete_record",
      description: "Permanently delete a record",
      annotations: { destructiveHint: true, idempotentHint: false },
      inputSchema: { type: "object", properties: { record_id: { type: "string" } } },
    },
  ],
}));
```

## Evaluation phase

Evaluations test whether an LLM can effectively use your MCP server to answer realistic questions using only the tools you provide. Run this phase after build + tests pass.

### When to create evals

Create `evaluation.xml` once the MCP server is functional and the tool schemas are stable. Do not create evals while tool names or schemas are still changing.

### Format

```xml
<evaluation>
  <qa_pair>
    <question>Your question here</question>
    <answer>Single verifiable answer</answer>
  </qa_pair>
</evaluation>
```

Create 10 Q&A pairs. Each question must be:
- **Independent** — does not depend on another question's answer
- **Read-only** — answerable without modifying any state
- **Complex** — requires multiple (potentially dozens of) tool calls
- **Realistic** — reflects an actual human use case
- **Verifiable** — has a single answer checkable by string comparison
- **Stable** — based on historical/closed data; the answer will not change

### Answer requirements

- One value only (no lists, no structured output)
- Human-readable preferred (name, date, count) over opaque IDs
- Specify the exact format in the question when ambiguity exists (e.g., "Use YYYY/MM/DD")

### Process

1. Read API/server documentation — understand available data
2. Inspect tool schemas — understand inputs, outputs, descriptions
3. Explore content read-only — make small, targeted calls with `limit` < 10
4. Draft 10 questions — follow all question/answer requirements above
5. Verify — solve each question yourself using the MCP tools; fix wrong answers

### Running evals

Use `scripts/evaluation.py` (in this skill's `scripts/` directory):

```bash
# stdio server (script launches it automatically)
python scripts/evaluation.py -t stdio -c python -a my_server.py evaluation.xml

# SSE or HTTP server (start server first)
python scripts/evaluation.py -t sse -u https://example.com/mcp \
  -H "Authorization: Bearer token" evaluation.xml
```

See `references/evaluation.md` for full question/answer guidelines and anti-patterns.
