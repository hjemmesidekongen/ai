import { describe, it, expect } from 'vitest';
import { evaluate } from '../src/hooks/claude-md-guardian.ts';
import type { HookInput } from '@kronen/hook-utils';

describe('claude-md-guardian', () => {
  function makeInput(filePath: string): HookInput {
    return { tool_name: 'Write', tool_input: { file_path: filePath } };
  }

  it('notifies when CLAUDE.md is modified', () => {
    const result = evaluate(makeInput('/project/CLAUDE.md'));
    expect(result.mode).toBe('notify');
    expect(result.systemMessage).toContain('CLAUDE.md guardian');
  });

  it('notifies for nested CLAUDE.md paths', () => {
    const result = evaluate(makeInput('/project/plugins/kronen/CLAUDE.md'));
    expect(result.mode).toBe('notify');
  });

  it('is case-insensitive', () => {
    const result = evaluate(makeInput('/project/claude.md'));
    expect(result.mode).toBe('notify');
  });

  it('allows non-CLAUDE.md files', () => {
    const result = evaluate(makeInput('/project/src/app.ts'));
    expect(result.mode).toBe('allow');
  });

  it('allows empty input', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('allows when no file_path in input', () => {
    const result = evaluate({ tool_name: 'Write', tool_input: {} });
    expect(result.mode).toBe('allow');
  });
});
