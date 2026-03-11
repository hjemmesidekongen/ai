#!/usr/bin/env bash
# kronen — SessionStart hook: verify Pencil MCP has spawn_agents enabled
# Checks ~/.claude.json for the -enable_spawn_agents flag.
# Outputs a warning if missing so the user can fix it before starting design work.
# Always exits 0.

set -euo pipefail

CLAUDE_CONFIG="$HOME/.claude.json"

if [ ! -f "$CLAUDE_CONFIG" ]; then
  exit 0
fi

# Check if pencil MCP server is configured at all
if ! grep -q '"pencil"' "$CLAUDE_CONFIG" 2>/dev/null; then
  exit 0
fi

# Check if spawn_agents flag is present
if ! grep -q 'enable_spawn_agents' "$CLAUDE_CONFIG" 2>/dev/null; then
  echo "=== Pencil Swarm Warning ==="
  echo "Pencil MCP is configured but -enable_spawn_agents flag is MISSING."
  echo "spawn_agents tool will not be available. Design work requires swarm mode."
  echo "Fix: add \"-enable_spawn_agents\" to mcpServers.pencil.args in ~/.claude.json"
  echo "=== End Warning ==="
fi

exit 0
