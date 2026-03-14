import { createRunner, projectPath } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { constructPlanPrompt } from '../utils/plan-prompt-constructor.ts';

/**
 * Stop hook: prevents session exit when an autopilot loop is active.
 * Reads the session state file, checks iteration/max/completion promise,
 * and either allows exit or blocks it with the next iteration prompt.
 */
export function evaluate(input: HookInput): HookResult {
  const sessionId = extractSessionId(input);
  const stateFile = projectPath('.claude', `autopilot-${sessionId}.local.md`);

  if (!existsSync(stateFile)) return { mode: 'allow' };

  const frontmatter = parseFrontmatter(stateFile);
  if (!frontmatter) {
    cleanup(stateFile);
    return { mode: 'allow' };
  }

  const { iteration, maxIterations, completionPromise, dynamicPlan } = frontmatter;

  // Max iterations check
  if (maxIterations > 0 && iteration >= maxIterations) {
    cleanup(stateFile);
    return { mode: 'allow' };
  }

  // Get last assistant output
  const lastOutput = extractLastOutput(input);
  if (!lastOutput) {
    cleanup(stateFile);
    return { mode: 'allow' };
  }

  // Check completion promise
  if (completionPromise) {
    const promiseMatch = extractPromiseTag(lastOutput);
    if (promiseMatch === completionPromise) {
      cleanup(stateFile);
      return { mode: 'allow' };
    }
  }

  // Not complete — build next iteration prompt
  const nextIteration = iteration + 1;
  const promptText = getPromptText(stateFile, dynamicPlan);
  if (!promptText) {
    cleanup(stateFile);
    return { mode: 'allow' };
  }

  // Update iteration counter
  updateIteration(stateFile, nextIteration);

  const systemMsg = completionPromise
    ? `Autopilot iteration ${nextIteration} | To stop: output <promise>${completionPromise}</promise> (ONLY when statement is TRUE - do not lie to exit!)`
    : `Autopilot iteration ${nextIteration} | No completion promise set - loop runs until max iterations (${maxIterations})`;

  return {
    mode: 'block',
    reason: promptText,
    systemMessage: systemMsg,
  };
}

function extractSessionId(input: HookInput): string {
  const rawId = typeof input.session_id === 'string' ? input.session_id : '';
  return rawId.replace(/[^a-zA-Z0-9_-]/g, '') || 'unknown';
}

interface Frontmatter {
  iteration: number;
  maxIterations: number;
  completionPromise: string;
  dynamicPlan: string;
}

function parseFrontmatter(stateFile: string): Frontmatter | null {
  try {
    const content = readFileSync(stateFile, 'utf-8');
    const fmMatch = /^---\n([\s\S]*?)\n---/m.exec(content);
    if (!fmMatch) return null;

    const fm = fmMatch[1];
    const iteration = parseInt(extractField(fm, 'iteration'), 10);
    const maxIterations = parseInt(extractField(fm, 'max_iterations'), 10);

    if (isNaN(iteration) || isNaN(maxIterations)) return null;

    return {
      iteration,
      maxIterations,
      completionPromise: extractField(fm, 'completion_promise'),
      dynamicPlan: extractField(fm, 'dynamic_plan'),
    };
  } catch {
    return null;
  }
}

function extractField(text: string, field: string): string {
  const regex = new RegExp(`^${field}:\\s*(.+)$`, 'm');
  const match = regex.exec(text);
  if (!match) return '';
  return match[1].replace(/^["']|["']$/g, '').trim();
}

function extractLastOutput(input: HookInput): string {
  const lastMsg = input['last_assistant_message'];
  if (typeof lastMsg === 'string' && lastMsg.length > 0) return lastMsg;

  const transcriptPath = input['transcript_path'];
  if (typeof transcriptPath === 'string' && existsSync(transcriptPath)) {
    try {
      const content = readFileSync(transcriptPath, 'utf-8');
      const lines = content.split('\n').filter((l) => l.includes('"role":"assistant"'));
      const lastLine = lines[lines.length - 1];
      if (lastLine) {
        const parsed = JSON.parse(lastLine) as Record<string, unknown>;
        const msgContent = (parsed.message as Record<string, unknown>)?.content;
        if (Array.isArray(msgContent)) {
          return (msgContent as Array<{ type: string; text: string }>)
            .filter((c) => c.type === 'text')
            .map((c) => String(c.text))
            .join('\n');
        }
      }
    } catch { /* skip */ }
  }

  return '';
}

function extractPromiseTag(text: string): string {
  const match = /<promise>([\s\S]*?)<\/promise>/.exec(text);
  if (!match) return '';
  return match[1].trim().replace(/\s+/g, ' ');
}

function getPromptText(stateFile: string, dynamicPlan: string): string {
  if (dynamicPlan && dynamicPlan !== 'null') {
    const prompt = constructPlanPrompt(dynamicPlan);
    return prompt || buildDynamicPromptFallback(dynamicPlan);
  }

  // Static mode — extract prompt from state file (after second ---)
  try {
    const content = readFileSync(stateFile, 'utf-8');
    const parts = content.split('---');
    if (parts.length >= 3) {
      return parts.slice(2).join('---').trim();
    }
  } catch { /* skip */ }

  return '';
}

function buildDynamicPromptFallback(planDir: string): string {
  const planState = projectPath(planDir, 'state.yml');
  if (!existsSync(planState)) return '';

  try {
    const content = readFileSync(planState, 'utf-8');
    if (content.includes('status: done')) return '';
    return `Execute the next cycle of the dynamic plan at ${planDir}`;
  } catch {
    return '';
  }
}

function updateIteration(stateFile: string, nextIteration: number): void {
  try {
    const content = readFileSync(stateFile, 'utf-8');
    const updated = content.replace(/^iteration:\s*\d+/m, `iteration: ${nextIteration}`);
    writeFileSync(stateFile, updated);
  } catch { /* best-effort */ }
}

function cleanup(stateFile: string): void {
  try { unlinkSync(stateFile); } catch { /* ignore */ }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
