import { createRunner } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { assembleContext } from '../utils/assemble-context.ts';

/**
 * PreCompact hook: captures session context before compaction
 * by building snapshot.yml via the shared assembler.
 */
export function evaluate(_input: HookInput): HookResult {
  assembleContext('precompact');
  return { mode: 'allow' };
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
