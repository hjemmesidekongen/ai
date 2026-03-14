import { createRunner, homeDir } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { rmSync } from 'node:fs';
import { join } from 'node:path';

/**
 * Stop hook: clear plugin cache at session end.
 * Prevents stale cache from persisting across sessions in this dev workspace.
 */
export function evaluate(_input: HookInput): HookResult {
  const home = homeDir();
  if (!home) {
    return { mode: 'allow' };
  }

  const cacheDir = join(home, '.claude', 'plugins', 'cache', 'hjemmesidekongen-ai');

  try {
    rmSync(cacheDir, { recursive: true, force: true });
  } catch {
    // Fail silently — cache clear is best-effort
  }

  return { mode: 'allow' };
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
