import { describe, it, expect, afterEach, beforeEach } from 'vitest';
import { mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/pencil-swarm-check.ts';

describe('pencil-swarm-check', () => {
  const testHome = join(tmpdir(), 'pencil-swarm-test');
  const configPath = join(testHome, '.claude.json');
  const originalEnv = { ...process.env };

  beforeEach(() => {
    mkdirSync(testHome, { recursive: true });
    process.env['HOME'] = testHome;
    process.env['USERPROFILE'] = testHome;
  });

  afterEach(() => {
    rmSync(testHome, { recursive: true, force: true });
    process.env = { ...originalEnv };
  });

  it('returns allow when no .claude.json exists', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when pencil MCP is not configured', () => {
    writeFileSync(configPath, JSON.stringify({ mcpServers: { other: {} } }));
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when pencil has spawn_agents enabled', () => {
    writeFileSync(
      configPath,
      JSON.stringify({
        mcpServers: {
          pencil: { args: ['-enable_spawn_agents'] },
        },
      }),
    );
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns warn when pencil is configured but spawn_agents is missing', () => {
    writeFileSync(
      configPath,
      JSON.stringify({
        mcpServers: {
          pencil: { args: [] },
        },
      }),
    );
    const result = evaluate({});
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('enable_spawn_agents');
  });
});
