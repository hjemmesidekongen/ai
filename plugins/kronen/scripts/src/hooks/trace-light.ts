import { createRunner, projectPath } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { appendFileSync, mkdirSync, readFileSync, renameSync, existsSync } from 'node:fs';
import { dirname } from 'node:path';

const ERROR_SIGNALS = /Exit code|No such file|Permission denied|command not found|ENOENT|EACCES/;
const MAX_CONTEXT_LENGTH = 120;
const BASH_CONTEXT_LENGTH = 80;

/** MCP field names to try for context extraction, in priority order. */
const MCP_CONTEXT_FIELDS = [
  'operations', 'patterns', 'query', 'prompt', 'filePathOrNew',
  'topic', 'skill', 'tags', 'name',
];

/**
 * PostToolUse hook (always-on): appends one pipe-delimited line per tool
 * invocation to trace-light.log.
 * Format: timestamp|tool_name|status|context
 */
export function evaluate(input: HookInput): HookResult {
  const toolName = input.tool_name;
  if (!toolName) return { mode: 'allow' };

  const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
  const status = detectStatus(input);
  const context = extractContext(toolName, input);

  writeTraceEntry(timestamp, toolName, status, context);
  return { mode: 'allow' };
}

function detectStatus(input: HookInput): 'success' | 'error' {
  if (input.is_error === true) return 'error';

  const toolResult = input.tool_result;
  if (typeof toolResult === 'string' && ERROR_SIGNALS.test(toolResult)) {
    return 'error';
  }

  return 'success';
}

function extractContext(toolName: string, input: HookInput): string {
  const toolInput = input.tool_input ?? {};
  let context = '';

  switch (toolName) {
    case 'Write':
    case 'Edit':
    case 'Read':
      context = stringField(toolInput, 'file_path');
      break;

    case 'Bash':
      context = truncate(stringField(toolInput, 'command'), BASH_CONTEXT_LENGTH);
      break;

    case 'Grep':
    case 'Glob':
      context = stringField(toolInput, 'pattern');
      break;

    case 'Skill':
      context = stringField(toolInput, 'skill');
      break;

    case 'Agent':
      context = stringField(toolInput, 'description') || stringField(toolInput, 'prompt');
      context = truncate(context, BASH_CONTEXT_LENGTH);
      break;

    default:
      if (toolName.startsWith('mcp__')) {
        context = extractMcpContext(toolInput);
      } else {
        context = stringField(toolInput, 'file_path') || stringField(toolInput, 'command');
      }
  }

  // Sanitize: replace pipe delimiters, enforce max length
  context = context.replace(/\|/g, '/');
  if (!context) context = '-';
  return truncate(context, MAX_CONTEXT_LENGTH);
}

function extractMcpContext(toolInput: Record<string, unknown>): string {
  for (const field of MCP_CONTEXT_FIELDS) {
    const value = stringField(toolInput, field);
    if (value) return truncate(value, BASH_CONTEXT_LENGTH);
  }
  return Object.keys(toolInput).length > 0 ? '(structured input)' : '';
}

function stringField(obj: Record<string, unknown>, key: string): string {
  const value = obj[key];
  return typeof value === 'string' ? value : '';
}

function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str;
  return str.slice(0, maxLength - 3) + '...';
}

function writeTraceEntry(timestamp: string, tool: string, status: string, context: string): void {
  try {
    const traceFile = projectPath('.ai', 'traces', 'trace-light.log');
    mkdirSync(dirname(traceFile), { recursive: true });

    // Log rotation — date-based
    rotateIfNewDay(traceFile, timestamp);

    appendFileSync(traceFile, `${timestamp}|${tool}|${status}|${context}\n`);
  } catch {
    // Best-effort
  }
}

function rotateIfNewDay(traceFile: string, currentTimestamp: string): void {
  if (!existsSync(traceFile)) return;

  try {
    const content = readFileSync(traceFile, 'utf-8');
    const firstLine = content.split('\n')[0] ?? '';
    const firstDate = firstLine.split('T')[0];
    const today = currentTimestamp.split('T')[0];

    if (firstDate && firstDate !== today) {
      renameSync(traceFile, traceFile.replace('.log', `-${firstDate}.log`));
    }
  } catch {
    // Rotation failure is non-critical
  }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
