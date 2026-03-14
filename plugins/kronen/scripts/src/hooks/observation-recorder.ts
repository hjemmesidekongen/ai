import { createRunner, projectPath, isTracingDisabled } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { appendFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname } from 'node:path';

const MAX_OBSERVATIONS = 500;
const ERROR_KEYWORDS = /error:|failed|not found|no such file|permission denied/i;

interface Observation {
  timestamp: string;
  tool: string;
  outcome: 'success' | 'error';
  context_type: string;
  sequence_key: string;
  error_summary: string | null;
}

/**
 * PostToolUse hook: records structured observations from tool calls
 * to .ai/instincts/observations.jsonl for instinct extraction.
 * Non-blocking — always returns allow.
 */
export function evaluate(input: HookInput): HookResult {
  if (isTracingDisabled()) return { mode: 'allow' };

  const toolName = input.tool_name ?? 'unknown';

  const observation = buildObservation(toolName, input);
  writeObservation(observation);

  return { mode: 'allow' };
}

function buildObservation(toolName: string, input: HookInput): Observation {
  const toolOutput = typeof input.tool_result === 'string' ? input.tool_result.slice(0, 2000) : '';
  const outcome = detectOutcome(input, toolOutput);
  const errorSummary = outcome === 'error' ? extractErrorSummary(toolOutput) : null;

  return {
    timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
    tool: toolName,
    outcome,
    context_type: inferContextType(toolName),
    sequence_key: computeSequenceKey(),
    error_summary: errorSummary,
  };
}

function detectOutcome(input: HookInput, toolOutput: string): 'success' | 'error' {
  if (input.is_error === true) return 'error';
  if (ERROR_KEYWORDS.test(toolOutput)) return 'error';
  return 'success';
}

function extractErrorSummary(toolOutput: string): string | null {
  const lines = toolOutput.split('\n');
  const errorLine = lines.find((line) => ERROR_KEYWORDS.test(line));
  return errorLine ? errorLine.slice(0, 80) : null;
}

function inferContextType(toolName: string): string {
  const lower = toolName.toLowerCase();
  if (/bash|grep|glob/.test(lower)) return 'search';
  if (/edit|write/.test(lower)) return 'write';
  if (/read/.test(lower)) return 'review';
  return 'general';
}

function computeSequenceKey(): string {
  try {
    const traceFile = projectPath('.ai', 'traces', 'trace-light.log');
    const content = readFileSync(traceFile, 'utf-8');
    const lines = content.trim().split('\n');
    const last3 = lines.slice(-3);
    const tools = last3.map((line) => line.split('|')[1] ?? '').join('-');
    return createHash('md5').update(tools).digest('hex').slice(0, 8);
  } catch {
    return 'none';
  }
}

function writeObservation(observation: Observation): void {
  try {
    const filePath = projectPath('.ai', 'instincts', 'observations.jsonl');
    mkdirSync(dirname(filePath), { recursive: true });

    appendFileSync(filePath, JSON.stringify(observation) + '\n');
    trimObservations(filePath);
  } catch {
    // Best-effort
  }
}

function trimObservations(filePath: string): void {
  try {
    const content = readFileSync(filePath, 'utf-8');
    const lines = content.trim().split('\n');
    if (lines.length > MAX_OBSERVATIONS) {
      const trimmed = lines.slice(-MAX_OBSERVATIONS).join('\n') + '\n';
      writeFileSync(filePath, trimmed);
    }
  } catch {
    // Best-effort trimming
  }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
