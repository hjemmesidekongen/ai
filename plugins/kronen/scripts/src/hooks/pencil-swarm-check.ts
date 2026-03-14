import { createRunner, homeDir } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const WARNING_MESSAGE = `=== Pencil Swarm Warning ===
Pencil MCP is configured but -enable_spawn_agents flag is MISSING.
spawn_agents tool will not be available. Design work requires swarm mode.
Fix: add "-enable_spawn_agents" to mcpServers.pencil.args in ~/.claude.json
=== End Warning ===`;

/**
 * SessionStart hook: verify Pencil MCP has spawn_agents enabled.
 * Outputs a warning if the flag is missing. Never blocks.
 */
export function evaluate(_input: HookInput): HookResult {
  const home = homeDir();
  if (!home) return { mode: 'allow' };

  let content: string;
  try {
    content = readFileSync(join(home, '.claude.json'), 'utf-8');
  } catch {
    return { mode: 'allow' };
  }

  if (!content.includes('"pencil"')) {
    return { mode: 'allow' };
  }

  if (!content.includes('enable_spawn_agents')) {
    return { mode: 'warn', message: WARNING_MESSAGE };
  }

  return { mode: 'allow' };
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
