---
name: mcp-creator
description: >
  Create and configure MCP server integrations for Claude Code plugins. Use when
  adding external service connections, setting up .mcp.json, configuring stdio/SSE/HTTP/WebSocket
  servers, or integrating MCP tools into commands and agents.
user_invocable: false
interactive: false
depends_on: [plugin-creator]
reads:
  - "plugins/*/.claude-plugin/plugin.json"
  - "plugins/*/.mcp.json"
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "config_valid_json"
      verify: "MCP configuration parses as valid JSON"
      fail_action: "Fix JSON syntax per references/process.md"
    - name: "server_type_correct"
      verify: "Server type has required fields (command for stdio, url for sse/http/ws)"
      fail_action: "Add missing fields per references/server-types.md"
    - name: "portable_paths"
      verify: "All paths use ${CLAUDE_PLUGIN_ROOT}, no hardcoded absolute paths"
      fail_action: "Replace absolute paths with ${CLAUDE_PLUGIN_ROOT}"
model_tier: senior
_source:
  origin: "claude-core"
  inspired_by: "https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev/skills/mcp-integration"
  ported_date: "2026-03-09"
  iteration: 1
  changes: "Adapted from Anthropic mcp-integration skill. Restructured for 80-line SKILL.md with project conventions."
---

# MCP Creator

Create and configure MCP server integrations for Claude Code plugins.

## When to trigger

- Adding external service connections to a plugin
- Setting up `.mcp.json` configuration
- Configuring stdio, SSE, HTTP, or WebSocket MCP servers
- Integrating MCP tools into commands or agents
- Debugging MCP server connectivity issues

## Server types

| Type | Transport | Best for | Auth method |
|------|-----------|----------|-------------|
| stdio | Child process (stdin/stdout) | Local tools, custom servers, NPM packages | Env vars |
| sse | HTTP + Server-Sent Events | Hosted services, cloud APIs | OAuth (auto) |
| http | REST requests | API backends, token auth | Bearer/API key |
| ws | WebSocket | Real-time streaming, low-latency | Bearer/headers |

## Configuration methods

| Method | Location | When to use |
|--------|----------|-------------|
| `.mcp.json` | Plugin root | Multiple servers, clean separation (recommended) |
| `mcpServers` in plugin.json | `.claude-plugin/plugin.json` | Single server, simple plugins |

## Tool naming

Format: `mcp__plugin_<plugin-name>_<server-name>__<tool-name>`

Pre-allow specific tools in command frontmatter via `allowed-tools`. Avoid wildcards.

## Tool annotations

Add hints so Claude reasons about safety: `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint`. See `references/process.md`.

## Evaluation

After build + tests pass, create `evaluation.xml` with 10 read-only Q&A pairs. See `references/evaluation.md`.

## References

- `references/process.md` — workflow, auth, tool annotations; `references/evaluation.md` — eval; `references/server-types.md` — types; `assets/*.json` — configs
