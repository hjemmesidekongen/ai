import { createRunner, projectPath, parseYamlFile } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readdirSync, appendFileSync, mkdirSync } from 'node:fs';
import { join, basename, dirname } from 'node:path';

/** Files that never need scope checking. */
const ALWAYS_ALLOWED = [
  /SKILL\.md$/, /CLAUDE\.md$/, /ecosystem\.json$/, /plugin\.json$/, /README\.md$/,
  /state\.yml$/, /decisions\.yml$/, /findings\.md$/, /roadmap\.yml$/, /MEMORY\.md$/,
  /\.log$/, /snapshot\.yml$/, /\.gitignore$/,
  /trace-light\.log$/, /observations\.jsonl$/, /instincts\.yml$/,
];

interface PlanState {
  plan?: string;
  status?: string;
  current_wave?: string;
  waves?: Record<string, { tasks?: string[] }>;
  tasks?: Record<string, { writes?: string[] }>;
  scope?: { paths?: { include?: string[] } };
}

/**
 * PreToolUse hook (Write|Edit): advisory scope warning for active plan tasks.
 * Warns when writing files not declared in the current wave's task writes
 * or outside scope.paths.include. Never blocks.
 */
export function evaluate(input: HookInput): HookResult {
  const filePath = extractFilePath(input);
  if (!filePath) return { mode: 'allow' };

  if (ALWAYS_ALLOWED.some((p) => p.test(filePath))) return { mode: 'allow' };

  const plan = findActivePlan();
  if (!plan) return { mode: 'allow' };

  const warnings: string[] = [];

  // Check task-level writes
  const taskWriteWarning = checkTaskWrites(filePath, plan);
  if (taskWriteWarning) warnings.push(taskWriteWarning);

  // Check plan-level scope.paths.include
  const scopeWarning = checkScopeIncludes(filePath, plan);
  if (scopeWarning) warnings.push(scopeWarning);

  if (warnings.length > 0) {
    logWarnings(filePath, plan.plan ?? '', warnings);
    return { mode: 'warn', message: warnings.join('\n') };
  }

  return { mode: 'allow' };
}

function extractFilePath(input: HookInput): string | null {
  const toolInput = input.tool_input;
  if (!toolInput) return null;
  const filePath = toolInput.file_path;
  return typeof filePath === 'string' && filePath.length > 0 ? filePath : null;
}

function findActivePlan(): PlanState | null {
  const plansDir = projectPath('.ai', 'plans');
  if (!existsSync(plansDir)) return null;

  try {
    for (const entry of readdirSync(plansDir, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      const stateFile = join(plansDir, entry.name, 'state.yml');
      if (!existsSync(stateFile)) continue;
      const state = parseYamlFile<PlanState>(stateFile);
      if (state?.status === 'in_progress') return state;
    }
  } catch { /* skip */ }

  return null;
}

function checkTaskWrites(filePath: string, plan: PlanState): string | null {
  const wave = plan.current_wave;
  if (!wave || wave === 'null') return null;

  const waveData = plan.waves?.[wave];
  const taskIds = waveData?.tasks ?? [];
  if (taskIds.length === 0) return null;

  const declaredWrites: string[] = [];
  for (const taskId of taskIds) {
    const task = plan.tasks?.[taskId];
    if (task?.writes) declaredWrites.push(...task.writes);
  }
  if (declaredWrites.length === 0) return null;

  for (const wp of declaredWrites) {
    if (filePath === wp || filePath.endsWith(wp)) return null;
  }

  return `SCOPE GUARD: "${basename(filePath)}" not in declared writes for wave "${wave}" (plan: ${plan.plan ?? 'unknown'}).\n  Confirm intent or add path to the task writes list in state.yml.`;
}

function checkScopeIncludes(filePath: string, plan: PlanState): string | null {
  const includes = plan.scope?.paths?.include;
  if (!includes || includes.length === 0) return null;

  for (const pattern of includes) {
    if (matchGlob(filePath, pattern)) return null;
  }

  return `SCOPE GUARD: "${basename(filePath)}" is outside plan scope.paths.include (plan: ${plan.plan ?? 'unknown'}).\n  This file does not match any include pattern. Confirm intent.`;
}

function matchGlob(filePath: string, pattern: string): boolean {
  // Convert glob to regex: ** -> .*, * -> [^/]*, ? -> .
  let regex = pattern
    .replace(/\*\*/g, '<<<GLOBSTAR>>>')
    .replace(/\*/g, '[^/]*')
    .replace(/<<<GLOBSTAR>>>/g, '.*')
    .replace(/\?/g, '.');
  regex = `^${regex}$`;

  try {
    return new RegExp(regex).test(filePath);
  } catch {
    return false;
  }
}

function logWarnings(filePath: string, planName: string, warnings: string[]): void {
  try {
    const logPath = projectPath('.ai', 'traces', 'hook-errors.log');
    mkdirSync(dirname(logPath), { recursive: true });
    const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    for (const warning of warnings) {
      const summary = warning.split('\n')[0].slice(0, 120);
      appendFileSync(logPath, `${timestamp}|plan-scope-guard|warn|${filePath}|${summary}\n`);
    }
  } catch { /* best-effort */ }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
