import { createRunner } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { assembleContext } from '../utils/assemble-context.ts';

/**
 * Stop hook: captures session context before exit
 * by building snapshot.yml via the shared assembler.
 */
export function evaluate(_input: HookInput): HookResult {
  assembleContext('stop');
  return { mode: 'allow' };
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
