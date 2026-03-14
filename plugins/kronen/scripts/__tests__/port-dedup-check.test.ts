import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/port-dedup-check.ts';

describe('port-dedup-check', () => {
  const testDir = join(tmpdir(), 'port-dedup-test');
  const pluginsDir = join(testDir, 'plugins');

  beforeEach(() => {
    mkdirSync(pluginsDir, { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function createPlugin(name: string, ecosystem: Record<string, string[]>): void {
    const dir = join(pluginsDir, name, '.claude-plugin');
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, 'ecosystem.json'), JSON.stringify(ecosystem));
  }

  it('returns allow when no ecosystem files exist', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when no duplicates', () => {
    createPlugin('alpha', { skills: ['skill-a'], commands: ['cmd-a'] });
    createPlugin('beta', { skills: ['skill-b'], commands: ['cmd-b'] });
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('notifies when duplicate skill names found', () => {
    createPlugin('alpha', { skills: ['shared-skill', 'unique-a'] });
    createPlugin('beta', { skills: ['shared-skill', 'unique-b'] });
    const result = evaluate({});
    expect(result.mode).toBe('notify');
    expect(result.systemMessage).toContain('shared-skill');
    expect(result.systemMessage).toContain('alpha');
    expect(result.systemMessage).toContain('beta');
  });

  it('notifies when duplicate command names found across plugins', () => {
    createPlugin('alpha', { commands: ['my-cmd'] });
    createPlugin('beta', { commands: ['my-cmd'] });
    const result = evaluate({});
    expect(result.mode).toBe('notify');
  });

  it('handles malformed ecosystem.json gracefully', () => {
    const dir = join(pluginsDir, 'bad', '.claude-plugin');
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, 'ecosystem.json'), 'not json');
    createPlugin('good', { skills: ['skill-a'] });
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
