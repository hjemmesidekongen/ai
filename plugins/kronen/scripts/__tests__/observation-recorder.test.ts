import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/observation-recorder.ts';

interface Observation {
  timestamp: string;
  tool: string;
  outcome: string;
  context_type: string;
}

function parseObservation(line: string): Observation {
  return JSON.parse(line) as Observation;
}

describe('observation-recorder', () => {
  const testDir = join(tmpdir(), 'observation-recorder-test');
  const observationsFile = join(testDir, '.ai', 'instincts', 'observations.jsonl');

  beforeEach(() => {
    mkdirSync(join(testDir, '.ai', 'instincts'), { recursive: true });
    process.env['CLAUDE_PROJECT_DIR'] = testDir;
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
    delete process.env['CLAUDE_PROJECT_DIR'];
  });

  it('records an observation with tool name', () => {
    evaluate({ tool_name: 'Write' });
    expect(existsSync(observationsFile)).toBe(true);
    const obs = parseObservation(readFileSync(observationsFile, 'utf-8').trim());
    expect(obs.tool).toBe('Write');
    expect(obs.outcome).toBe('success');
  });

  it('detects error outcome from tool result', () => {
    evaluate({
      tool_name: 'Bash',
      tool_result: 'Error: command not found',
      is_error: true,
    });
    const obs = parseObservation(readFileSync(observationsFile, 'utf-8').trim());
    expect(obs.outcome).toBe('error');
  });

  it('infers context type from tool name', () => {
    evaluate({ tool_name: 'Edit' });
    const obs = parseObservation(readFileSync(observationsFile, 'utf-8').trim());
    expect(obs.context_type).toBe('write');
  });

  it('infers search context for Bash/Grep', () => {
    evaluate({ tool_name: 'Grep' });
    const obs = parseObservation(readFileSync(observationsFile, 'utf-8').trim());
    expect(obs.context_type).toBe('search');
  });

  it('infers review context for Read', () => {
    evaluate({ tool_name: 'Read' });
    const obs = parseObservation(readFileSync(observationsFile, 'utf-8').trim());
    expect(obs.context_type).toBe('review');
  });

  it('trims file to 500 lines when exceeded', () => {
    const lines = Array.from({ length: 510 }, (_, i) =>
      JSON.stringify({ timestamp: '2026-01-01', tool: `T${i}`, outcome: 'success' }),
    ).join('\n') + '\n';
    writeFileSync(observationsFile, lines);

    evaluate({ tool_name: 'Read' });

    const content = readFileSync(observationsFile, 'utf-8');
    const lineCount = content.trim().split('\n').length;
    expect(lineCount).toBeLessThanOrEqual(500);
  });

  it('handles missing tool name gracefully', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('includes timestamp in observation', () => {
    evaluate({ tool_name: 'Write' });
    const obs = parseObservation(readFileSync(observationsFile, 'utf-8').trim());
    expect(obs.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });
});
