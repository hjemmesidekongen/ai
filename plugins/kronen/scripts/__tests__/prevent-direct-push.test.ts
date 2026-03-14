import { describe, it, expect } from 'vitest';
import { evaluate } from '../src/hooks/prevent-direct-push.ts';
import type { HookInput } from '@kronen/hook-utils';

function makeInput(command: string): HookInput {
  return {
    tool_name: 'Bash',
    tool_input: { command },
  };
}

describe('prevent-direct-push', () => {
  it('blocks push to main', () => {
    const result = evaluate(makeInput('git push origin main'));
    expect(result.mode).toBe('block');
    expect(result.reason).toContain('main');
  });

  it('blocks push to master', () => {
    const result = evaluate(makeInput('git push origin master'));
    expect(result.mode).toBe('block');
    expect(result.reason).toContain('master');
  });

  it('blocks push to production', () => {
    const result = evaluate(makeInput('git push origin production'));
    expect(result.mode).toBe('block');
  });

  it('blocks push to release branches', () => {
    const result = evaluate(makeInput('git push origin release/1.0'));
    expect(result.mode).toBe('block');
    expect(result.reason).toContain('release');
  });

  it('blocks force push to protected branch', () => {
    const result = evaluate(makeInput('git push --force origin main'));
    expect(result.mode).toBe('block');
    expect(result.reason).toMatch(/[Ff]orce/);
  });

  it('blocks force push with -f flag', () => {
    const result = evaluate(makeInput('git push -f origin main'));
    expect(result.mode).toBe('block');
  });

  it('allows push to feature branch', () => {
    const result = evaluate(makeInput('git push origin feature/my-branch'));
    expect(result.mode).toBe('allow');
  });

  it('allows push with -u flag to feature branch', () => {
    const result = evaluate(makeInput('git push -u origin feature/my-branch'));
    expect(result.mode).toBe('allow');
  });

  it('allows non-push git commands', () => {
    const result = evaluate(makeInput('git status'));
    expect(result.mode).toBe('allow');
  });

  it('allows non-Bash tools', () => {
    const result = evaluate({ tool_name: 'Write', tool_input: { file_path: '/test' } });
    expect(result.mode).toBe('allow');
  });

  it('allows empty input', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('blocks push with branch:refspec syntax', () => {
    const result = evaluate(makeInput('git push origin HEAD:main'));
    expect(result.mode).toBe('block');
  });
});
