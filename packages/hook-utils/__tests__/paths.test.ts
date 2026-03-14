import { describe, it, expect, afterEach } from 'vitest';
import { projectDir, pluginRoot, tempDir, projectPath, homeDir } from '../src/paths.ts';

describe('paths', () => {
  const originalEnv = { ...process.env };

  afterEach(() => {
    process.env = { ...originalEnv };
  });

  it('projectDir uses CLAUDE_PROJECT_DIR when set', () => {
    process.env['CLAUDE_PROJECT_DIR'] = '/test/project';
    expect(projectDir()).toBe('/test/project');
  });

  it('projectDir falls back to cwd', () => {
    delete process.env['CLAUDE_PROJECT_DIR'];
    expect(projectDir()).toBe(process.cwd());
  });

  it('pluginRoot uses CLAUDE_PLUGIN_ROOT when set', () => {
    process.env['CLAUDE_PLUGIN_ROOT'] = '/test/plugin';
    expect(pluginRoot()).toBe('/test/plugin');
  });

  it('pluginRoot returns empty string when not set', () => {
    delete process.env['CLAUDE_PLUGIN_ROOT'];
    expect(pluginRoot()).toBe('');
  });

  it('tempDir returns a valid path', () => {
    expect(tempDir()).toBeTruthy();
    expect(typeof tempDir()).toBe('string');
  });

  it('projectPath joins segments to project dir', () => {
    process.env['CLAUDE_PROJECT_DIR'] = '/test/project';
    const result = projectPath('.ai', 'traces', 'trace-light.log');
    expect(result).toBe('/test/project/.ai/traces/trace-light.log');
  });

  it('homeDir returns a value', () => {
    expect(homeDir()).toBeTruthy();
  });
});
