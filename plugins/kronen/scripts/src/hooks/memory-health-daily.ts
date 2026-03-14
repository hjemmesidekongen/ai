import { createRunner, projectPath, readProfileCache } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { runHealthCheck } from '../utils/memory-health-check.ts';

/**
 * SessionStart hook: runs memory health check at most once per day.
 * Uses a timestamp marker file to skip if already run today.
 */
export function evaluate(_input: HookInput): HookResult {
  const flags = readProfileCache();
  if (flags.get('KRONEN_DOC_CHECKPOINT') === 'disabled') return { mode: 'allow' };

  const markerFile = projectPath('.ai', '.memory-health-last-run');
  const today = new Date().toISOString().slice(0, 10);

  if (existsSync(markerFile)) {
    try {
      const lastRun = readFileSync(markerFile, 'utf-8').trim();
      if (lastRun === today) return { mode: 'allow' };
    } catch { /* continue */ }
  }

  const report = runHealthCheck();

  // Update marker
  try {
    mkdirSync(dirname(markerFile), { recursive: true });
    writeFileSync(markerFile, today + '\n');
  } catch { /* best-effort */ }

  if (report.includes('Action needed') || report.includes('OVER LIMIT')) {
    return { mode: 'warn', message: report };
  }

  return { mode: 'allow' };
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
