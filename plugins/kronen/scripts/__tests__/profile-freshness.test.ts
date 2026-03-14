import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate, computeConfigHash } from '../src/hooks/profile-freshness.ts';

describe('profile-freshness', () => {
  const testDir = join(tmpdir(), 'profile-freshness-test');

  beforeEach(() => {
    mkdirSync(testDir, { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  it('returns allow when no project-map.yml exists', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when no workspace config files exist', () => {
    mkdirSync(join(testDir, '.ai'), { recursive: true });
    writeFileSync(join(testDir, '.ai', 'project-map.yml'), 'content_hash: "abc123"\n');
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when hash matches', () => {
    writeFileSync(join(testDir, 'package.json'), '{"name":"test"}');
    mkdirSync(join(testDir, '.ai'), { recursive: true });

    const hash = computeConfigHash();
    writeFileSync(join(testDir, '.ai', 'project-map.yml'), `content_hash: "${hash}"\n`);

    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('warns when hash differs', () => {
    writeFileSync(join(testDir, 'package.json'), '{"name":"test"}');
    mkdirSync(join(testDir, '.ai'), { recursive: true });
    writeFileSync(join(testDir, '.ai', 'project-map.yml'), 'content_hash: "stale-hash"\n');

    const result = evaluate({});
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('stale');
  });

  it('returns allow when project-map.yml has no content_hash', () => {
    writeFileSync(join(testDir, 'package.json'), '{"name":"test"}');
    mkdirSync(join(testDir, '.ai'), { recursive: true });
    writeFileSync(join(testDir, '.ai', 'project-map.yml'), 'repo_type: single-package\n');

    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
