import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/tdd-gate.ts';
import type { HookInput } from '@kronen/hook-utils';

describe('tdd-gate', () => {
  const testDir = join(tmpdir(), 'tdd-gate-test');
  const srcDir = join(testDir, 'src');
  const testsDir = join(testDir, 'src', '__tests__');

  beforeEach(() => {
    mkdirSync(testsDir, { recursive: true });
    mkdirSync(join(testDir, '.ai', 'traces'), { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
    delete process.env['CLAUDE_NO_TDD_GATE'];
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
    delete process.env['CLAUDE_NO_TDD_GATE'];
  });

  function makeInput(filePath: string): HookInput {
    return { tool_name: 'Write', tool_input: { file_path: filePath } };
  }

  it('blocks when no test file exists for a .ts file', () => {
    writeFileSync(join(srcDir, 'auth.ts'), '');
    const result = evaluate(makeInput(join(srcDir, 'auth.ts')));
    expect(result.mode).toBe('block');
    expect(result.reason).toContain('auth');
  });

  it('allows when test file exists nearby', () => {
    writeFileSync(join(srcDir, 'auth.ts'), '');
    writeFileSync(join(testsDir, 'auth.test.ts'), '');
    const result = evaluate(makeInput(join(srcDir, 'auth.ts')));
    expect(result.mode).toBe('allow');
  });

  it('allows test files themselves', () => {
    const result = evaluate(makeInput(join(testsDir, 'auth.test.ts')));
    expect(result.mode).toBe('allow');
  });

  it('allows spec files', () => {
    const result = evaluate(makeInput('src/auth.spec.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows non-production extensions', () => {
    const result = evaluate(makeInput('src/styles.css'));
    expect(result.mode).toBe('allow');
  });

  it('allows config files', () => {
    const result = evaluate(makeInput('tsconfig.json'));
    expect(result.mode).toBe('allow');
  });

  it('allows files in test directories', () => {
    const result = evaluate(makeInput('src/__tests__/helper.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows files in scripts directory', () => {
    const result = evaluate(makeInput('plugins/kronen/scripts/build.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows when opt-out env var is set', () => {
    process.env['CLAUDE_NO_TDD_GATE'] = '1';
    writeFileSync(join(srcDir, 'auth.ts'), '');
    const result = evaluate(makeInput(join(srcDir, 'auth.ts')));
    expect(result.mode).toBe('allow');
  });

  it('allows when opt-out file exists', () => {
    mkdirSync(join(testDir, '.claude'), { recursive: true });
    writeFileSync(join(testDir, '.claude', 'no-tdd-gate'), '');
    writeFileSync(join(srcDir, 'auth.ts'), '');
    const result = evaluate(makeInput(join(srcDir, 'auth.ts')));
    expect(result.mode).toBe('allow');
  });

  it('allows d.ts files', () => {
    const result = evaluate(makeInput('src/types.d.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows migration files', () => {
    const result = evaluate(makeInput('src/migrations/20260101.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows empty input', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
