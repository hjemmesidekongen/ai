import { createRunner, projectPath, isTracingDisabled } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

/** Patterns that indicate a test/build/lint command worth logging on failure. */
const RELEVANT_PATTERNS = [
  /test|jest|vitest|pytest|mocha|cypress/,
  /build|compile|tsc|webpack|vite|esbuild/,
  /lint|eslint|prettier|stylelint/,
  /make|cargo|go build|go test/,
  /npm run|yarn|pnpm|bun run/,
];

/**
 * PostToolUse hook (Bash): captures failed test/build/lint command outputs
 * to .ai/traces/debug-failures.log for debugging visibility.
 * Non-blocking — always returns allow.
 */
export function evaluate(input: HookInput): HookResult {
  if (isTracingDisabled()) return { mode: 'allow' };

  const exitCode = extractExitCode(input);
  if (exitCode === null || exitCode === 0) return { mode: 'allow' };

  const command = extractCommand(input);
  if (!command) return { mode: 'allow' };

  const isRelevant = RELEVANT_PATTERNS.some((pattern) => pattern.test(command));
  if (!isRelevant) return { mode: 'allow' };

  logFailure(command, exitCode, extractStderr(input));
  return { mode: 'allow' };
}

function extractExitCode(input: HookInput): number | null {
  // Check direct field first
  if (typeof input['exit_code'] === 'number') return input['exit_code'];

  // Try to extract from tool_result string
  const toolResult = input.tool_result;
  if (typeof toolResult === 'string') {
    const match = /exit_code["\s:]+(\d+)/.exec(toolResult);
    if (match) return parseInt(match[1], 10);
  }

  return null;
}

function extractCommand(input: HookInput): string | null {
  const toolInput = input.tool_input;
  if (!toolInput) return null;
  const command = toolInput.command;
  return typeof command === 'string' && command.length > 0 ? command : null;
}

function extractStderr(input: HookInput): string {
  const stderr = input['stderr'];
  if (typeof stderr === 'string') return stderr.slice(0, 500);

  const toolResult = input.tool_result;
  if (typeof toolResult === 'string') {
    const match = /"stderr":"((?:[^"\\]|\\.)*)"/.exec(toolResult);
    if (match) return match[1].slice(0, 500);
  }

  return '';
}

function logFailure(command: string, exitCode: number, stderr: string): void {
  try {
    const logPath = projectPath('.ai', 'traces', 'debug-failures.log');
    mkdirSync(dirname(logPath), { recursive: true });

    const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    let entry = `---\ntimestamp: ${timestamp}\ncommand: "${command}"\nexit_code: ${exitCode}\n`;
    if (stderr) entry += `stderr_snippet: "${stderr}"\n`;
    entry += '\n';

    appendFileSync(logPath, entry);
  } catch {
    // Best-effort logging
  }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
