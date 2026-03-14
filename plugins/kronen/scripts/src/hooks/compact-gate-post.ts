import { createRunner, projectDir } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

/** Patterns that mark a unit-completion artifact. */
const UNIT_COMPLETION_PATTERNS = [
  /\/SKILL\.md$/,
  /\/commands\/[^/]+\.md$/,
  /\/agents\/[^/]+\.md$/,
  /decisions\.yml$/,
  /\/findings\.md$/,
];

/**
 * PostToolUse hook (Write|Edit): detects unit-completion artifacts and sets
 * .ai/compact-needed flag. When a unit's final artifact is written, this flags
 * compact as needed before the next unit begins.
 */
export function evaluate(input: HookInput): HookResult {
  const filePath = extractFilePath(input);
  if (!filePath) return { mode: 'allow' };

  const isUnitCompletion =
    UNIT_COMPLETION_PATTERNS.some((pattern) => pattern.test(filePath)) ||
    isWaveCompletion(filePath, input);

  if (isUnitCompletion) {
    writeCompactFlag();
  }

  return { mode: 'allow' };
}

function extractFilePath(input: HookInput): string | null {
  const toolInput = input.tool_input;
  if (!toolInput) return null;
  const filePath = toolInput.file_path;
  return typeof filePath === 'string' && filePath.length > 0 ? filePath : null;
}

function isWaveCompletion(filePath: string, input: HookInput): boolean {
  if (!filePath.includes('plans/') || !filePath.endsWith('state.yml')) {
    return false;
  }
  // Check if the write content contains a wave completion signal
  const inputStr = JSON.stringify(input.tool_input ?? {});
  return inputStr.includes('status: done') || inputStr.includes('status: completed');
}

function writeCompactFlag(): void {
  try {
    const dir = join(projectDir(), '.ai');
    mkdirSync(dir, { recursive: true });
    const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    writeFileSync(join(dir, 'compact-needed'), timestamp + '\n');
  } catch {
    // Best-effort — don't break the hook pipeline
  }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
