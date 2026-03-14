import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/verification-gate-stop.ts';

describe('verification-gate-stop', () => {
  const testDir = join(tmpdir(), 'verification-gate-test');
  const traceFile = join(testDir, '.ai', 'traces', 'trace-light.log');
  const plansDir = join(testDir, '.ai', 'plans');

  beforeEach(() => {
    mkdirSync(join(testDir, '.ai', 'traces'), { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function createActivePlan(name: string): void {
    const planDir = join(plansDir, name);
    mkdirSync(planDir, { recursive: true });
    writeFileSync(join(planDir, 'state.yml'), `plan: ${name}\nstatus: in_progress\n`);
  }

  function writeTrace(entries: string[]): void {
    writeFileSync(traceFile, entries.join('\n') + '\n');
  }

  it('returns allow when no active plan', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when no trace file', () => {
    createActivePlan('test');
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('notifies when writes happened without verification', () => {
    createActivePlan('test-plan');
    writeTrace([
      '2026-03-14T12:00:00Z|Write|success|src/app.ts',
      '2026-03-14T12:01:00Z|Edit|success|src/app.ts',
    ]);
    const result = evaluate({});
    expect(result.mode).toBe('notify');
    expect(result.systemMessage).toContain('test-plan');
    expect(result.systemMessage).toContain('verification');
  });

  it('returns allow when verification follows writes', () => {
    createActivePlan('test');
    writeTrace([
      '2026-03-14T12:00:00Z|Write|success|src/app.ts',
      '2026-03-14T12:01:00Z|Bash|success|pnpm test',
    ]);
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when only reads happened', () => {
    createActivePlan('test');
    writeTrace([
      '2026-03-14T12:00:00Z|Read|success|src/app.ts',
      '2026-03-14T12:01:00Z|Grep|success|pattern',
    ]);
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
