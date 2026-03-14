import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/plan-verification-gate.ts';
import type { HookInput } from '@kronen/hook-utils';

describe('plan-verification-gate', () => {
  const testDir = join(tmpdir(), 'plan-verif-gate-test');
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

  function createPlanWithWaves(
    name: string,
    currentWave: number,
    waveDefs: Array<{ wave: number; files: string[] }>,
    excludes?: string[],
  ): void {
    const planDir = join(plansDir, name);
    mkdirSync(planDir, { recursive: true });

    // state.yml
    const stateLines = [
      `plan: ${name}`,
      'status: in_progress',
      'planned_waves:',
      ...Array.from({ length: currentWave }, (_, i) => `  - ${i + 1}`),
    ];
    if (excludes) {
      stateLines.push('scope:', '  paths:', '    exclude:');
      for (const ex of excludes) stateLines.push(`      - "${ex}"`);
    }
    writeFileSync(join(planDir, 'state.yml'), stateLines.join('\n'));

    // plan.yml with wave definitions
    const planLines = ['plan: ' + name, 'waves:'];
    for (const wd of waveDefs) {
      planLines.push(`  - wave: ${wd.wave}`);
      planLines.push('    tasks:');
      planLines.push(`      - id: t${wd.wave}`);
      planLines.push('        files_written:');
      for (const f of wd.files) planLines.push(`          - "${f}"`);
    }
    writeFileSync(join(planDir, 'plan.yml'), planLines.join('\n'));
  }

  it('allows when no active plan', () => {
    const result = evaluate(makeInput('src/app.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows meta files (state.yml, plan.md, etc.)', () => {
    createPlanWithWaves('test', 1, [{ wave: 1, files: ['a.ts'] }]);
    expect(evaluate(makeInput('.ai/plans/test/state.yml')).mode).toBe('allow');
    expect(evaluate(makeInput('CLAUDE.md')).mode).toBe('allow');
    expect(evaluate(makeInput('.ai/traces/trace.log')).mode).toBe('allow');
  });

  it('allows files in current wave', () => {
    createPlanWithWaves('test', 1, [
      { wave: 1, files: ['src/current.ts'] },
      { wave: 2, files: ['src/future.ts'] },
    ]);
    const result = evaluate(makeInput('src/current.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows files not claimed by any wave', () => {
    createPlanWithWaves('test', 1, [{ wave: 1, files: ['src/a.ts'] }]);
    const result = evaluate(makeInput('src/unclaimed.ts'));
    expect(result.mode).toBe('allow');
  });

  it('blocks files in a future wave', () => {
    createPlanWithWaves('test', 1, [
      { wave: 1, files: ['src/current.ts'] },
      { wave: 2, files: ['src/future.ts'] },
    ]);
    const result = evaluate(makeInput('src/future.ts'));
    expect(result.mode).toBe('block');
    expect(result.reason).toContain('future wave');
  });

  it('blocks files matching scope.paths.exclude', () => {
    createPlanWithWaves('test', 1, [{ wave: 1, files: ['src/a.ts'] }], ['site/**']);
    const result = evaluate(makeInput('site/app.tsx'));
    expect(result.mode).toBe('block');
    expect(result.reason).toContain('exclude');
  });

  it('allows empty input', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
