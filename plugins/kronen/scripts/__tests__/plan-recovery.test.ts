import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/plan-recovery.ts';

describe('plan-recovery', () => {
  const testDir = join(tmpdir(), 'plan-recovery-test');
  const plansDir = join(testDir, '.ai', 'plans');

  beforeEach(() => {
    mkdirSync(plansDir, { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function createPlan(name: string, status: string, cycle = 1, remaining = 'Some work left'): void {
    const planDir = join(plansDir, name);
    mkdirSync(planDir, { recursive: true });
    writeFileSync(join(planDir, 'state.yml'), [
      `plan: ${name}`,
      `status: ${status}`,
      `cycle: ${cycle}`,
      `remaining_goal: "${remaining}"`,
      `updated_at: "2026-03-14T12:00:00Z"`,
    ].join('\n'));
  }

  it('returns allow when no plans directory exists', () => {
    rmSync(plansDir, { recursive: true, force: true });
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when no active plans', () => {
    createPlan('test-plan', 'done');
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('warns with plan details when active plan exists', () => {
    createPlan('my-plan', 'in_progress', 3, 'Migrate remaining hooks');
    const result = evaluate({});
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('my-plan');
    expect(result.message).toContain('cycle 3');
    expect(result.message).toContain('Migrate remaining hooks');
    expect(result.message).toContain('/plan resume');
  });

  it('reports multiple active plans', () => {
    createPlan('plan-a', 'in_progress', 1, 'Work A');
    createPlan('plan-b', 'in_progress', 2, 'Work B');
    const result = evaluate({});
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('plan-a');
    expect(result.message).toContain('plan-b');
  });

  it('truncates long remaining_goal', () => {
    const longGoal = 'A'.repeat(100);
    createPlan('long-plan', 'in_progress', 1, longGoal);
    const result = evaluate({});
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('...');
  });
});
