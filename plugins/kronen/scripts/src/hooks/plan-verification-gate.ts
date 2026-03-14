import { createRunner, projectPath, parseYamlFile, readProfileCache } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readdirSync, appendFileSync, mkdirSync } from 'node:fs';
import { join, basename, dirname } from 'node:path';

/** Files that bypass verification gating. */
const SKIP_PATTERNS = [
  /state\.yml$/, /learnings\.yml$/, /plan\.yml$/, /plan\.md$/,
  /\/artifacts\//, /\/\.ai\//, /CLAUDE\.md$/, /MEMORY\.md$/, /\.log$/,
];

interface PlanState {
  plan?: string;
  status?: string;
  planned_waves?: string[];
  scope?: { paths?: { exclude?: string[] } };
}

interface WaveDef {
  wave: number | string;
  tasks?: Array<{ id?: string; files_written?: string[] }>;
}

interface PlanYml {
  waves?: WaveDef[];
}

/**
 * PreToolUse hook (Write|Edit): prevents writing to future wave files
 * before the current wave is verified. Also blocks writes matching
 * scope.paths.exclude patterns (unless a scope_override exists).
 */
export function evaluate(input: HookInput): HookResult {
  const flags = readProfileCache();
  if (flags.get('KRONEN_VERIFICATION') === 'disabled') return { mode: 'allow' };

  const filePath = extractFilePath(input);
  if (!filePath) return { mode: 'allow' };
  if (SKIP_PATTERNS.some((p) => p.test(filePath))) return { mode: 'allow' };

  const planInfo = findActivePlan();
  if (!planInfo) return { mode: 'allow' };

  // Check future wave ownership
  const futureWaveBlock = checkFutureWave(filePath, planInfo);
  if (futureWaveBlock) return futureWaveBlock;

  // Check scope.paths.exclude
  const excludeBlock = checkScopeExcludes(filePath, planInfo);
  if (excludeBlock) return excludeBlock;

  return { mode: 'allow' };
}

function extractFilePath(input: HookInput): string | null {
  const toolInput = input.tool_input;
  if (!toolInput) return null;
  const filePath = toolInput.file_path;
  return typeof filePath === 'string' && filePath.length > 0 ? filePath : null;
}

interface ActivePlanInfo {
  state: PlanState;
  stateFile: string;
  planDir: string;
  planYml: PlanYml | null;
  currentWave: string;
}

function findActivePlan(): ActivePlanInfo | null {
  const plansDir = projectPath('.ai', 'plans');
  if (!existsSync(plansDir)) return null;

  try {
    for (const entry of readdirSync(plansDir, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      const stateFile = join(plansDir, entry.name, 'state.yml');
      if (!existsSync(stateFile)) continue;

      const state = parseYamlFile<PlanState>(stateFile);
      if (state?.status !== 'in_progress') continue;

      const plannedWaves = state.planned_waves ?? [];
      const currentWave = plannedWaves.length > 0 ? String(plannedWaves[plannedWaves.length - 1]) : '';
      if (!currentWave) continue;

      const planDir = join(plansDir, entry.name);
      const planYmlFile = join(planDir, 'plan.yml');
      const planYml = existsSync(planYmlFile) ? parseYamlFile<PlanYml>(planYmlFile) : null;

      return { state, stateFile, planDir, planYml, currentWave };
    }
  } catch { /* fail open */ }

  return null;
}

function checkFutureWave(filePath: string, info: ActivePlanInfo): HookResult | null {
  if (!info.planYml?.waves) return null;

  let pastCurrent = false;
  for (const waveDef of info.planYml.waves) {
    const waveName = String(waveDef.wave);

    if (pastCurrent) {
      // Check if file belongs to this future wave
      for (const task of waveDef.tasks ?? []) {
        for (const declaredFile of task.files_written ?? []) {
          if (filePath === declaredFile || filePath.endsWith('/' + declaredFile)) {
            logBlock(filePath, 'file belongs to future wave, current wave not yet verified');
            return {
              mode: 'block',
              reason: `File "${basename(filePath)}" belongs to a future wave. Complete and verify the current wave (${info.currentWave}) first.`,
            };
          }
        }
      }
    }

    if (waveName === info.currentWave) pastCurrent = true;
  }

  return null;
}

function checkScopeExcludes(filePath: string, info: ActivePlanInfo): HookResult | null {
  const excludes = info.state.scope?.paths?.exclude;
  if (!excludes || excludes.length === 0) return null;

  for (const pattern of excludes) {
    if (matchGlob(filePath, pattern)) {
      // Check for scope_override in plan.yml
      if (hasOverride(filePath, info.planYml)) return null;

      logBlock(filePath, `matches scope.paths.exclude pattern: ${pattern}`);
      return {
        mode: 'block',
        reason: `File "${basename(filePath)}" matches scope.paths.exclude pattern "${pattern}". Add scope_override to the task in plan.yml if this is intentional.`,
      };
    }
  }

  return null;
}

function hasOverride(filePath: string, planYml: PlanYml | null): boolean {
  if (!planYml?.waves) return false;
  // Check scope_override entries in all tasks
  for (const wave of planYml.waves) {
    for (const task of wave.tasks ?? []) {
      const overrides = (task as Record<string, unknown>).scope_override as string[] | undefined;
      if (!overrides) continue;
      for (const override of overrides) {
        if (matchGlob(filePath, override)) return true;
      }
    }
  }
  return false;
}

function matchGlob(filePath: string, pattern: string): boolean {
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

function logBlock(filePath: string, detail: string): void {
  try {
    const logPath = projectPath('.ai', 'traces', 'hook-errors.log');
    mkdirSync(dirname(logPath), { recursive: true });
    const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    appendFileSync(logPath, `${timestamp}|plan-verification-gate|block|${filePath}|${detail}\n`);
  } catch { /* best-effort */ }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
