import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/check-trace-written.ts';

describe('check-trace-written', () => {
  const testDir = join(tmpdir(), 'check-trace-test');

  beforeEach(() => {
    mkdirSync(testDir, { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function setupProject(active: string, tracesDir?: string): string {
    const projectDir = join(testDir, '.ai', 'projects', active);
    const trDir = tracesDir ?? join(projectDir, 'traces');
    mkdirSync(trDir, { recursive: true });

    // agency.yml
    mkdirSync(join(testDir, '.ai'), { recursive: true });
    writeFileSync(join(testDir, '.ai', 'agency.yml'), `active: ${active}\n`);

    // state.yml
    mkdirSync(projectDir, { recursive: true });
    writeFileSync(join(projectDir, 'state.yml'), [
      'tracing:',
      '  enabled: true',
      `  traces_dir: "${trDir}"`,
    ].join('\n'));

    return trDir;
  }

  it('returns allow when no agency.yml exists', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when no recent trace files exist', () => {
    setupProject('test-project');
    // No trace files in the directory
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when all traces have reflections', () => {
    setupProject('test-project');
    const trDir = join(testDir, '.ai', 'projects', 'test-project', 'traces');
    writeFileSync(join(trDir, 'skill-20260314T120000.yml'), 'name: test\nreflections:\n  - good');
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('notifies when trace is missing reflections', () => {
    setupProject('test-project');
    const trDir = join(testDir, '.ai', 'projects', 'test-project', 'traces');
    writeFileSync(join(trDir, 'skill-20260314T120000.yml'), 'name: test\nresults:\n  - done');
    const result = evaluate({});
    expect(result.mode).toBe('notify');
    expect(result.systemMessage).toContain('missing reflections');
  });

  it('handles missing state.yml gracefully', () => {
    mkdirSync(join(testDir, '.ai'), { recursive: true });
    writeFileSync(join(testDir, '.ai', 'agency.yml'), 'active: nonexistent\n');
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
