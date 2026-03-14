import { createRunner, projectPath } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { readFileSync, existsSync } from 'node:fs';

const SAMPLE_INTERVAL = 10;
const THRESHOLD = 50;

/**
 * PostToolUse advisory hook: suggests /compact when context depth is high.
 * Counts trace-light.log lines as a proxy for session tool call depth.
 * Samples every 10th call. Fires at 50, 100, 150+ calls.
 * Never blocks. Never sets compact-needed flag.
 */
export function evaluate(_input: HookInput): HookResult {
  const traceFile = projectPath('.ai', 'traces', 'trace-light.log');

  if (!existsSync(traceFile)) {
    return { mode: 'allow' };
  }

  let lineCount: number;
  try {
    const content = readFileSync(traceFile, 'utf-8');
    lineCount = content.split('\n').filter((line) => line.length > 0).length;
  } catch {
    return { mode: 'allow' };
  }

  if (lineCount % SAMPLE_INTERVAL !== 0 || lineCount < THRESHOLD) {
    return { mode: 'allow' };
  }

  // Don't pile on if compact-needed flag is already set
  if (existsSync(projectPath('.ai', 'compact-needed'))) {
    return { mode: 'allow' };
  }

  return {
    mode: 'warn',
    message: `Context depth: ~${lineCount} tool calls this session. Consider running /compact to preserve context quality.`,
  };
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
