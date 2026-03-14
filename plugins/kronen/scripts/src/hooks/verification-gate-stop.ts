import { createRunner, projectPath } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const WRITE_TOOLS = new Set(['Write', 'Edit']);
const VERIFY_TOOLS = new Set(['Bash', 'Read', 'Grep']);
const TAIL_LINES = 30;

/**
 * Stop hook: checks whether recent writes have been followed by verification.
 * If an active plan exists and the last operations were writes without any
 * Bash/Read/Grep after them, emits an advisory reminder.
 */
export function evaluate(_input: HookInput): HookResult {
  const activePlan = findActivePlan();
  if (!activePlan) return { mode: 'allow' };

  const traceFile = projectPath('.ai', 'traces', 'trace-light.log');
  if (!existsSync(traceFile)) return { mode: 'allow' };

  const needsVerification = checkTraceForUnverifiedWrites(traceFile);
  if (!needsVerification) return { mode: 'allow' };

  return {
    mode: 'notify',
    reason: 'Verification reminder.',
    systemMessage: `Plan '${activePlan}' has recent writes with no verification step. Run proof before marking tasks done (verification-gate protocol).`,
  };
}

function findActivePlan(): string | null {
  const plansDir = projectPath('.ai', 'plans');
  if (!existsSync(plansDir)) return null;

  try {
    const entries = readdirSync(plansDir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const stateFile = join(plansDir, entry.name, 'state.yml');
      if (!existsSync(stateFile)) continue;

      const content = readFileSync(stateFile, 'utf-8');
      if (/^status:\s*in_progress$/m.test(content)) {
        const nameMatch = /^plan:\s*(.+)$/m.exec(content);
        return nameMatch ? nameMatch[1].replace(/["']/g, '').trim() : entry.name;
      }
    }
  } catch {
    // Fail silently
  }

  return null;
}

function checkTraceForUnverifiedWrites(traceFile: string): boolean {
  try {
    const content = readFileSync(traceFile, 'utf-8');
    const lines = content.trim().split('\n');
    const recent = lines.slice(-TAIL_LINES);

    let lastWriteLine = -1;
    let lastVerifyLine = -1;

    for (let i = 0; i < recent.length; i++) {
      const tool = recent[i].split('|')[1] ?? '';
      if (WRITE_TOOLS.has(tool)) lastWriteLine = i;
      if (VERIFY_TOOLS.has(tool)) lastVerifyLine = i;
    }

    return lastWriteLine > -1 && lastVerifyLine < lastWriteLine;
  } catch {
    return false;
  }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
