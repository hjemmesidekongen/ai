import { createRunner, projectPath, parseYamlFile } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

/** Patterns for unit-completion artifacts that bypass the gate. */
const UNIT_COMPLETION_PATTERNS = [
  /\/SKILL\.md$/,
  /\/commands\/[^/]+\.md$/,
  /\/agents\/[^/]+\.md$/,
  /decisions\.yml$/,
  /\/findings\.md$/,
  /\.ai\/plans\/[^/]+\/state\.yml$/,
  /plans\/[^/]+\/state\.yml$/,
];

/**
 * PreToolUse hook (Write|Edit): blocks writes when compact is needed AND the target
 * file is not a unit-completion artifact AND not owned by an active plan's current wave.
 * Exit 0 = allow, exit 2 = block.
 */
export function evaluate(input: HookInput): HookResult {
  const flagFile = projectPath('.ai', 'compact-needed');
  if (!existsSync(flagFile)) return { mode: 'allow' };

  const filePath = extractFilePath(input);
  if (!filePath) return { mode: 'allow' };

  // Allow unit-completion artifacts through
  if (UNIT_COMPLETION_PATTERNS.some((p) => p.test(filePath))) {
    return { mode: 'allow' };
  }

  // Check if file is owned by an active plan's current wave
  if (isOwnedByActiveWave(filePath)) {
    return { mode: 'allow' };
  }

  return {
    mode: 'block',
    reason: 'Compact required before starting next unit. Run /compact, then retry.',
  };
}

function extractFilePath(input: HookInput): string | null {
  const toolInput = input.tool_input;
  if (!toolInput) return null;
  const filePath = toolInput.file_path;
  return typeof filePath === 'string' && filePath.length > 0 ? filePath : null;
}

interface PlanState {
  status?: string;
  current_wave?: string;
  waves?: Record<string, { tasks?: string[] }>;
  tasks?: Record<string, { writes?: string[] }>;
}

function isOwnedByActiveWave(filePath: string): boolean {
  const plansDir = projectPath('.ai', 'plans');
  if (!existsSync(plansDir)) return false;

  try {
    const entries = readdirSync(plansDir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const stateFile = join(plansDir, entry.name, 'state.yml');
      if (!existsSync(stateFile)) continue;

      const state = parseYamlFile<PlanState>(stateFile);
      if (!state || state.status !== 'in_progress') continue;

      const currentWave = state.current_wave;
      if (!currentWave || currentWave === 'null') continue;

      // Get task IDs for the current wave
      const waveData = state.waves?.[currentWave];
      const taskIds = waveData?.tasks ?? [];

      // Check if the file is in any of those tasks' writes
      for (const taskId of taskIds) {
        const taskData = state.tasks?.[taskId];
        const writes = taskData?.writes ?? [];
        for (const writePath of writes) {
          if (filePath.endsWith(writePath) || filePath === writePath) {
            return true;
          }
        }
      }
    }
  } catch {
    // Fail open
  }

  return false;
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
