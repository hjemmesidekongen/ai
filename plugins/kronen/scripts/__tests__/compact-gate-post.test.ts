import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/compact-gate-post.ts';
import type { HookInput } from '@kronen/hook-utils';

describe('compact-gate-post', () => {
  const testDir = join(tmpdir(), 'compact-gate-post-test');
  const aiDir = join(testDir, '.ai');
  const flagFile = join(aiDir, 'compact-needed');

  beforeEach(() => {
    mkdirSync(aiDir, { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function makeInput(filePath: string, extraInput?: string): HookInput {
    return {
      tool_name: 'Write',
      tool_input: { file_path: filePath, content: extraInput ?? '' },
    };
  }

  it('sets flag when SKILL.md is written', () => {
    evaluate(makeInput('plugins/kronen/skills/test/SKILL.md'));
    expect(existsSync(flagFile)).toBe(true);
  });

  it('sets flag when a command file is written', () => {
    evaluate(makeInput('plugins/kronen/commands/test.md'));
    expect(existsSync(flagFile)).toBe(true);
  });

  it('sets flag when an agent file is written', () => {
    evaluate(makeInput('plugins/kronen/agents/test.md'));
    expect(existsSync(flagFile)).toBe(true);
  });

  it('sets flag when decisions.yml is written', () => {
    evaluate(makeInput('.ai/brainstorm/topic/decisions.yml'));
    expect(existsSync(flagFile)).toBe(true);
  });

  it('sets flag when findings.md is written', () => {
    evaluate(makeInput('.ai/research/findings.md'));
    expect(existsSync(flagFile)).toBe(true);
  });

  it('sets flag when plan state.yml has wave completion', () => {
    const input: HookInput = {
      tool_name: 'Edit',
      tool_input: {
        file_path: '.ai/plans/test/state.yml',
        new_string: 'status: done',
      },
    };
    evaluate(input);
    expect(existsSync(flagFile)).toBe(true);
  });

  it('does NOT set flag for plan state.yml without completion signal', () => {
    evaluate(makeInput('.ai/plans/test/state.yml'));
    expect(existsSync(flagFile)).toBe(false);
  });

  it('does NOT set flag for regular files', () => {
    evaluate(makeInput('src/hooks/cache-clear.ts'));
    expect(existsSync(flagFile)).toBe(false);
  });

  it('does NOT set flag for empty input', () => {
    evaluate({});
    expect(existsSync(flagFile)).toBe(false);
  });

  it('writes ISO timestamp to flag file', () => {
    evaluate(makeInput('plugins/kronen/skills/test/SKILL.md'));
    const content = readFileSync(flagFile, 'utf-8').trim();
    expect(content).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);
  });
});
