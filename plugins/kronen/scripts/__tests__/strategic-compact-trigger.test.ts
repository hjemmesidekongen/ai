import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/strategic-compact-trigger.ts';

describe('strategic-compact-trigger', () => {
  const testDir = join(tmpdir(), 'compact-trigger-test');
  const tracesDir = join(testDir, '.ai', 'traces');
  const traceFile = join(tracesDir, 'trace-light.log');

  beforeEach(() => {
    mkdirSync(tracesDir, { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function writeTraceLines(count: number): void {
    const lines = Array.from({ length: count }, (_, i) =>
      `2026-03-14T12:00:00Z|Tool${i}|success|-`,
    ).join('\n') + '\n';
    writeFileSync(traceFile, lines);
  }

  it('returns allow when no trace file exists', () => {
    rmSync(traceFile, { force: true });
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when line count is below 50', () => {
    writeTraceLines(30);
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when line count is not a multiple of 10', () => {
    writeTraceLines(53);
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns warn at 50 lines', () => {
    writeTraceLines(50);
    const result = evaluate({});
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('50');
  });

  it('returns warn at 100 lines', () => {
    writeTraceLines(100);
    const result = evaluate({});
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('100');
  });

  it('returns allow when compact-needed flag exists', () => {
    writeTraceLines(50);
    mkdirSync(join(testDir, '.ai'), { recursive: true });
    writeFileSync(join(testDir, '.ai', 'compact-needed'), 'flagged');
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
