import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/compact-gate-pre.ts';
import type { HookInput } from '@kronen/hook-utils';

describe('compact-gate-pre', () => {
  const testDir = join(tmpdir(), 'compact-gate-pre-test');
  const flagFile = join(testDir, '.ai', 'compact-needed');
  const plansDir = join(testDir, '.ai', 'plans');

  beforeEach(() => {
    mkdirSync(join(testDir, '.ai'), { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function makeInput(filePath: string): HookInput {
    return { tool_name: 'Write', tool_input: { file_path: filePath } };
  }

  function setCompactNeeded(): void {
    writeFileSync(flagFile, '2026-03-14T12:00:00Z');
  }

  function createPlanWithWave(planName: string, wave: string, taskId: string, writes: string[]): void {
    const planDir = join(plansDir, planName);
    mkdirSync(planDir, { recursive: true });
    writeFileSync(join(planDir, 'state.yml'), [
      `plan: ${planName}`,
      'status: in_progress',
      `current_wave: ${wave}`,
      'waves:',
      `  ${wave}:`,
      `    tasks: [${taskId}]`,
      'tasks:',
      `  ${taskId}:`,
      '    writes:',
      ...writes.map((w) => `      - ${w}`),
    ].join('\n'));
  }

  it('allows when no compact-needed flag exists', () => {
    const result = evaluate(makeInput('src/app.ts'));
    expect(result.mode).toBe('allow');
  });

  it('blocks non-unit files when flag exists', () => {
    setCompactNeeded();
    const result = evaluate(makeInput('src/app.ts'));
    expect(result.mode).toBe('block');
    expect(result.reason).toContain('Compact required');
  });

  it('allows SKILL.md when flag exists', () => {
    setCompactNeeded();
    const result = evaluate(makeInput('plugins/kronen/skills/test/SKILL.md'));
    expect(result.mode).toBe('allow');
  });

  it('allows commands/*.md when flag exists', () => {
    setCompactNeeded();
    const result = evaluate(makeInput('plugins/kronen/commands/test.md'));
    expect(result.mode).toBe('allow');
  });

  it('allows agents/*.md when flag exists', () => {
    setCompactNeeded();
    const result = evaluate(makeInput('plugins/kronen/agents/test.md'));
    expect(result.mode).toBe('allow');
  });

  it('allows decisions.yml when flag exists', () => {
    setCompactNeeded();
    const result = evaluate(makeInput('.ai/brainstorm/topic/decisions.yml'));
    expect(result.mode).toBe('allow');
  });

  it('allows findings.md when flag exists', () => {
    setCompactNeeded();
    const result = evaluate(makeInput('research/findings.md'));
    expect(result.mode).toBe('allow');
  });

  it('allows plan state.yml when flag exists', () => {
    setCompactNeeded();
    const result = evaluate(makeInput('.ai/plans/test/state.yml'));
    expect(result.mode).toBe('allow');
  });

  it('allows file owned by active plan wave', () => {
    setCompactNeeded();
    createPlanWithWave('my-plan', 'wave-1', 't1', ['src/hooks/cache-clear.ts']);
    const result = evaluate(makeInput('src/hooks/cache-clear.ts'));
    expect(result.mode).toBe('allow');
  });

  it('blocks file not owned by active plan wave', () => {
    setCompactNeeded();
    createPlanWithWave('my-plan', 'wave-1', 't1', ['src/hooks/cache-clear.ts']);
    const result = evaluate(makeInput('src/unrelated-file.ts'));
    expect(result.mode).toBe('block');
  });

  it('allows empty input', () => {
    setCompactNeeded();
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
