import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate, gradePrompt } from '../src/hooks/prompt-grade.ts';

describe('prompt-grade', () => {
  const testDir = join(tmpdir(), 'prompt-grade-test');
  const logFile = join(testDir, '.ai', 'traces', 'hook-errors.log');

  beforeEach(() => {
    mkdirSync(join(testDir, '.ai', 'traces'), { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  it('passes clear high-stakes prompt with enough specificity', () => {
    // clarity >= 7 needed to pass with stakes=8 (refactor)
    // This prompt has: word count (3pts), file path (2pts), action verb (1pt), constraint (1pt), format keyword (0pts) = 7
    const result = evaluate({
      user_prompt: 'Refactor src/auth/middleware.ts to extract the session validation logic into a separate pure function called validateSession. Must keep all 12 existing tests passing without modification. Output the result as a single file.',
    });
    expect(result.mode).toBe('allow');
  });

  it('intervenes on vague high-stakes prompt', () => {
    const result = evaluate({
      user_prompt: 'refactor the authentication',
    });
    expect(result.mode).toBe('warn');
    expect(result.message).toContain('sharpen');
  });

  it('passes short low-stakes prompt', () => {
    const result = evaluate({
      user_prompt: 'show me the git status',
    });
    expect(result.mode).toBe('allow');
  });

  it('skips very short prompts', () => {
    const result = evaluate({ user_prompt: 'hi' });
    expect(result.mode).toBe('allow');
  });

  it('skips empty input', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  describe('gradePrompt scoring', () => {
    it('gives higher clarity for longer prompts with specifics', () => {
      const { clarity } = gradePrompt(
        'Add a new endpoint at src/api/users.ts that returns a JSON list of active users. Must use pagination with limit/offset parameters.',
      );
      expect(clarity).toBeGreaterThanOrEqual(6);
    });

    it('gives low clarity for vague prompts', () => {
      const { clarity } = gradePrompt('make it better');
      expect(clarity).toBeLessThanOrEqual(3);
    });

    it('detects high-stakes keywords', () => {
      const { stakes } = gradePrompt('migrate the database schema');
      expect(stakes).toBeGreaterThanOrEqual(8);
    });

    it('detects low-stakes keywords', () => {
      const { stakes } = gradePrompt('show me the logs');
      expect(stakes).toBeLessThanOrEqual(3);
    });

    it('defaults to medium stakes when no keywords match', () => {
      const { stakes } = gradePrompt('do something with the thing');
      expect(stakes).toBe(5);
    });
  });

  it('logs decisions to hook-errors.log', () => {
    evaluate({
      user_prompt: 'deploy the production database migration',
    });
    const logContent = readFileSync(logFile, 'utf-8');
    expect(logContent).toContain('prompt-grade');
  });
});
