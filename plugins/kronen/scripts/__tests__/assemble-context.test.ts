import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { assembleContext } from '../src/utils/assemble-context.ts';

describe('assemble-context', () => {
  const testDir = join(tmpdir(), 'assemble-context-test');
  const snapshotPath = join(testDir, '.ai', 'context', 'snapshot.yml');

  beforeEach(() => {
    mkdirSync(join(testDir, '.ai', 'context'), { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  it('creates snapshot.yml', () => {
    assembleContext('test');
    expect(existsSync(snapshotPath)).toBe(true);
  });

  it('includes source field', () => {
    assembleContext('precompact');
    const content = readFileSync(snapshotPath, 'utf-8');
    expect(content).toContain('source: "precompact"');
  });

  it('includes workspace section with branch', () => {
    assembleContext('test');
    const content = readFileSync(snapshotPath, 'utf-8');
    expect(content).toContain('workspace:');
    expect(content).toContain('branch:');
  });

  it('includes project section when agency.yml exists', () => {
    mkdirSync(join(testDir, '.ai'), { recursive: true });
    writeFileSync(join(testDir, '.ai', 'agency.yml'), 'active: test-project\n');
    mkdirSync(join(testDir, '.ai', 'projects', 'test-project'), { recursive: true });
    writeFileSync(
      join(testDir, '.ai', 'projects', 'test-project', 'state.yml'),
      'status: active\ncurrent_module: auth\n',
    );
    assembleContext('test');
    const content = readFileSync(snapshotPath, 'utf-8');
    expect(content).toContain('project:');
    expect(content).toContain('test-project');
  });

  it('sets project to null when no agency.yml', () => {
    assembleContext('test');
    const content = readFileSync(snapshotPath, 'utf-8');
    expect(content).toContain('project: null');
  });

  it('includes active plan when one exists', () => {
    const planDir = join(testDir, '.ai', 'plans', 'my-plan');
    mkdirSync(planDir, { recursive: true });
    writeFileSync(join(planDir, 'state.yml'), 'plan: my-plan\nstatus: in_progress\ncurrent_wave: wave-1\n');
    assembleContext('test');
    const content = readFileSync(snapshotPath, 'utf-8');
    expect(content).toContain('my-plan');
  });

  it('extracts modified files from trace-light.log', () => {
    mkdirSync(join(testDir, '.ai', 'traces'), { recursive: true });
    writeFileSync(
      join(testDir, '.ai', 'traces', 'trace-light.log'),
      '2026-03-14T12:00:00Z|Write|success|src/app.ts\n2026-03-14T12:01:00Z|Read|success|src/other.ts\n',
    );
    assembleContext('test');
    const content = readFileSync(snapshotPath, 'utf-8');
    expect(content).toContain('src/app.ts');
    // Read tool should not appear in modified_files
    expect(content).not.toContain('src/other.ts');
  });

  it('includes probes section', () => {
    assembleContext('test');
    const content = readFileSync(snapshotPath, 'utf-8');
    expect(content).toContain('probes:');
  });

  it('handles missing directories gracefully', () => {
    rmSync(testDir, { recursive: true, force: true });
    mkdirSync(testDir, { recursive: true });
    expect(() => assembleContext('test')).not.toThrow();
  });
});
