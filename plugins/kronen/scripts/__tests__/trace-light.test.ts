import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/trace-light.ts';
describe('trace-light', () => {
  const testDir = join(tmpdir(), 'trace-light-test');
  const tracesDir = join(testDir, '.ai', 'traces');
  const traceFile = join(tracesDir, 'trace-light.log');

  beforeEach(() => {
    mkdirSync(tracesDir, { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  function getLastLine(): string {
    return readFileSync(traceFile, 'utf-8').trim().split('\n').pop() ?? '';
  }

  it('logs Write tool with file_path context', () => {
    evaluate({ tool_name: 'Write', tool_input: { file_path: 'src/app.ts' } });
    const line = getLastLine();
    expect(line).toContain('|Write|success|src/app.ts');
  });

  it('logs Bash tool with command context (truncated)', () => {
    evaluate({ tool_name: 'Bash', tool_input: { command: 'a'.repeat(100) } });
    const line = getLastLine();
    expect(line).toContain('|Bash|success|');
    expect(line.split('|')[3].length).toBeLessThanOrEqual(120);
  });

  it('logs Grep tool with pattern context', () => {
    evaluate({ tool_name: 'Grep', tool_input: { pattern: 'foo.*bar' } });
    const line = getLastLine();
    expect(line).toContain('|Grep|success|foo.*bar');
  });

  it('logs Skill tool with skill name context', () => {
    evaluate({ tool_name: 'Skill', tool_input: { skill: 'plan-engine' } });
    const line = getLastLine();
    expect(line).toContain('|Skill|success|plan-engine');
  });

  it('logs Agent tool with description context', () => {
    evaluate({ tool_name: 'Agent', tool_input: { description: 'Review code' } });
    const line = getLastLine();
    expect(line).toContain('|Agent|success|Review code');
  });

  it('logs MCP tool with first field context', () => {
    evaluate({ tool_name: 'mcp__pencil__batch_design', tool_input: { operations: 'insert node' } });
    const line = getLastLine();
    expect(line).toContain('|mcp__pencil__batch_design|success|insert node');
  });

  it('detects error from is_error field', () => {
    evaluate({ tool_name: 'Bash', tool_input: { command: 'ls' }, is_error: true });
    const line = getLastLine();
    expect(line).toContain('|error|');
  });

  it('detects error from tool_result content', () => {
    evaluate({ tool_name: 'Bash', tool_input: { command: 'ls' }, tool_result: 'No such file or directory' });
    const line = getLastLine();
    expect(line).toContain('|error|');
  });

  it('sanitizes pipe characters in context', () => {
    evaluate({ tool_name: 'Bash', tool_input: { command: 'cat file | grep foo' } });
    const line = getLastLine();
    expect(line.split('|').length).toBe(4); // timestamp|tool|status|context
  });

  it('uses dash for missing context', () => {
    evaluate({ tool_name: 'Write', tool_input: {} });
    const line = getLastLine();
    expect(line).toContain('|Write|success|-');
  });

  it('does not log when tool_name is missing', () => {
    evaluate({});
    expect(existsSync(traceFile)).toBe(false);
  });

  it('rotates log on date change', () => {
    // Write an entry with yesterday's date
    writeFileSync(traceFile, '2020-01-01T00:00:00Z|Read|success|-\n');
    evaluate({ tool_name: 'Write', tool_input: { file_path: 'test.ts' } });

    // Old file should be rotated
    expect(existsSync(join(tracesDir, 'trace-light-2020-01-01.log'))).toBe(true);
    // New entry should be in current file
    const content = readFileSync(traceFile, 'utf-8');
    expect(content).toContain('test.ts');
  });

  it('appends ISO 8601 timestamp', () => {
    evaluate({ tool_name: 'Read', tool_input: { file_path: 'test.ts' } });
    const line = getLastLine();
    const timestamp = line.split('|')[0];
    expect(timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);
  });
});
