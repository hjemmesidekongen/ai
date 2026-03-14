import { createRunner } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';

const ADVISORY = `CLAUDE.md guardian: You just modified a CLAUDE.md file. Before continuing, validate this change:
1. Contradictions — does this conflict with any existing rule in CLAUDE.md or MEMORY.md?
2. Redundancy — is this already stated elsewhere? If so, consolidate rather than duplicate.
3. Consequences — what downstream behavior does this change? Could it break existing workflows?
4. Simplicity — is there a simpler alternative (a pointer instead of inline content, a skill instead of a rule)?
If the change fails any of these checks, revert or revise it now.`;

/**
 * PostToolUse hook (Write|Edit): fires when a CLAUDE.md file is modified.
 * Outputs advisory guidance for self-validation. Never blocks.
 */
export function evaluate(input: HookInput): HookResult {
  const toolInput = input.tool_input;
  if (!toolInput) return { mode: 'allow' };

  const filePath = toolInput.file_path;
  if (typeof filePath !== 'string' || filePath.length === 0) {
    return { mode: 'allow' };
  }

  if (!filePath.toUpperCase().includes('CLAUDE.MD')) {
    return { mode: 'allow' };
  }

  return { mode: 'notify', systemMessage: ADVISORY };
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
