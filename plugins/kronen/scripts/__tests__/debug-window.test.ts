import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/debug-window.ts';
import type { HookInput } from '@kronen/hook-utils';

describe('debug-window', () => {
  const testDir = join(tmpdir(), 'debug-window-test');
  const debugLog = join(testDir, '.ai', 'traces', 'debug-failures.log');

  beforeEach(() => {
    mkdirSync(join(testDir, '.ai', 'traces'), { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function makeInput(command: string, exitCode: number, stderr?: string): HookInput {
    const result: Record<string, unknown> = {
      tool_name: 'Bash',
      tool_input: { command },
      tool_result: JSON.stringify({ exit_code: exitCode, stderr: stderr ?? '' }),
    };
    // Flatten exit_code into the input for extraction
    result['exit_code'] = exitCode;
    if (stderr) result['stderr'] = stderr;
    return result as HookInput;
  }

  it('ignores successful commands', () => {
    evaluate(makeInput('pnpm run test', 0));
    expect(existsSync(debugLog)).toBe(false);
  });

  it('ignores failed non-test/build commands', () => {
    evaluate(makeInput('ls /nonexistent', 1));
    expect(existsSync(debugLog)).toBe(false);
  });

  it('logs failed test commands', () => {
    evaluate(makeInput('vitest run', 1));
    expect(existsSync(debugLog)).toBe(true);
    const content = readFileSync(debugLog, 'utf-8');
    expect(content).toContain('vitest run');
    expect(content).toContain('exit_code: 1');
  });

  it('logs failed build commands', () => {
    evaluate(makeInput('tsc --noEmit', 2));
    expect(existsSync(debugLog)).toBe(true);
  });

  it('logs failed lint commands', () => {
    evaluate(makeInput('eslint src/', 1));
    expect(existsSync(debugLog)).toBe(true);
  });

  it('logs pnpm/npm/yarn commands', () => {
    evaluate(makeInput('pnpm run build', 1));
    expect(existsSync(debugLog)).toBe(true);
  });

  it('includes stderr snippet when available', () => {
    evaluate(makeInput('vitest run', 1, 'Error: test failed'));
    const content = readFileSync(debugLog, 'utf-8');
    expect(content).toContain('Error: test failed');
  });

  it('returns allow mode always', () => {
    const result = evaluate(makeInput('vitest run', 1));
    expect(result.mode).toBe('allow');
  });

  it('handles empty input gracefully', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
