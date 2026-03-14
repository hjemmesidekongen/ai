import { describe, it, expect, vi, afterEach } from 'vitest';
import { evaluate } from '../src/hooks/doc-stale-check.ts';

// Mock execFileSync for git commands
vi.mock('node:child_process', () => ({
  execFileSync: vi.fn(),
}));

import { execFileSync } from 'node:child_process';
const mockExec = vi.mocked(execFileSync);

describe('doc-stale-check', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('returns allow when no files changed', () => {
    mockExec.mockReturnValue(Buffer.from(''));
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when only non-infrastructure files changed', () => {
    mockExec.mockReturnValue(Buffer.from('src/app.ts\nREADME.md\n'));
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('returns allow when infrastructure changed but docs also changed', () => {
    mockExec.mockReturnValue(Buffer.from(
      'plugins/kronen/skills/test/SKILL.md\nplugins/kronen/commands/test.md\nCLAUDE.md\n',
    ));
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('notifies when 2+ infrastructure files changed without doc updates', () => {
    mockExec.mockReturnValue(Buffer.from(
      'plugins/kronen/skills/test/SKILL.md\nplugins/kronen/commands/test.md\n',
    ));
    const result = evaluate({});
    expect(result.mode).toBe('notify');
    expect(result.systemMessage).toContain('doc-checkpoint');
  });

  it('returns allow when only 1 infrastructure file changed', () => {
    mockExec.mockReturnValue(Buffer.from('plugins/kronen/skills/test/SKILL.md\n'));
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('detects .claude-plugin/ as infrastructure', () => {
    mockExec.mockReturnValue(Buffer.from(
      'plugins/kronen/.claude-plugin/plugin.json\nplugins/kronen/scripts/test.ts\n',
    ));
    const result = evaluate({});
    expect(result.mode).toBe('notify');
  });

  it('returns allow when git fails', () => {
    mockExec.mockImplementation(() => { throw new Error('not a git repo'); });
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });
});
