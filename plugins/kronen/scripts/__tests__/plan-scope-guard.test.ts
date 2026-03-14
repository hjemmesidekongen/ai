import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/plan-scope-guard.ts';
import type { HookInput } from '@kronen/hook-utils';

describe('plan-scope-guard', () => {
  const testDir = join(tmpdir(), 'scope-guard-test');
  const plansDir = join(testDir, '.ai', 'plans');

  beforeEach(() => {
    mkdirSync(join(testDir, '.ai', 'traces'), { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function makeInput(filePath: string): HookInput {
    return { tool_name: 'Write', tool_input: { file_path: filePath } };
  }

  function createPlan(name: string, wave: string, taskId: string, writes: string[], includes?: string[]): void {
    const planDir = join(plansDir, name);
    mkdirSync(planDir, { recursive: true });
    const lines = [
      `plan: ${name}`,
      'status: in_progress',
      `current_wave: ${wave}`,
      'waves:',
      `  ${wave}:`,
      `    tasks: [${taskId}]`,
      'tasks:',
      `  ${taskId}:`,
      '    writes:',
      ...writes.map((w) => `      - ${w}`),
    ];
    if (includes) {
      lines.push('scope:', '  paths:', '    include:');
      for (const inc of includes) {
        lines.push(`      - "${inc}"`);
      }
    }
    writeFileSync(join(planDir, 'state.yml'), lines.join('\n'));
  }

  it('allows when no active plan', () => {
    const result = evaluate(makeInput('src/app.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows always-allowed files (SKILL.md, CLAUDE.md, etc.)', () => {
    createPlan('test', 'w1', 't1', ['other.ts']);
    expect(evaluate(makeInput('plugins/kronen/skills/test/SKILL.md')).mode).toBe('allow');
    expect(evaluate(makeInput('CLAUDE.md')).mode).toBe('allow');
    expect(evaluate(makeInput('.ai/traces/trace-light.log')).mode).toBe('allow');
  });

  it('allows file in declared writes', () => {
    createPlan('test', 'w1', 't1', ['src/hooks/cache-clear.ts']);
    const result = evaluate(makeInput('src/hooks/cache-clear.ts'));
    expect(result.mode).toBe('allow');
  });

  it('warns when file is not in declared writes', () => {
    createPlan('test', 'w1', 't1', ['src/hooks/cache-clear.ts']);
    const result = evaluate(makeInput('src/hooks/other.ts'));
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('not in declared writes');
  });

  it('warns when file is outside scope.paths.include', () => {
    createPlan('test', 'w1', 't1', ['src/app.ts'], ['src/**']);
    const result = evaluate(makeInput('docs/readme.md'));
    expect(result.mode).toBe('warn');
  });

  it('allows file matching scope.paths.include', () => {
    createPlan('test', 'w1', 't1', ['src/app.ts'], ['src/**']);
    const result = evaluate(makeInput('src/app.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows empty input', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
