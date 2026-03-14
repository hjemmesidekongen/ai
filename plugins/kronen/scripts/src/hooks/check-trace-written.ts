import { createRunner, projectPath, parseYamlFile } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, basename, resolve } from 'node:path';

const RECENT_WINDOW_MS = 60 * 60 * 1000; // 60 minutes

/**
 * Stop hook: checks whether trace files from the current session are missing
 * a reflections section. Advisory only — never blocks.
 */
export function evaluate(_input: HookInput): HookResult {
  const agencyFile = projectPath('.ai', 'agency.yml');
  if (!existsSync(agencyFile)) return { mode: 'allow' };

  const agency = parseYamlFile<{ active?: string }>(agencyFile);
  if (!agency?.active) return { mode: 'allow' };

  const stateFile = projectPath('.ai', 'projects', agency.active, 'state.yml');
  if (!existsSync(stateFile)) return { mode: 'allow' };

  const state = parseYamlFile<{
    tracing?: { enabled?: boolean; traces_dir?: string };
  }>(stateFile);

  if (!state?.tracing?.enabled) return { mode: 'allow' };

  const tracesDir = resolveTracesDir(state.tracing.traces_dir, agency.active);
  if (!tracesDir || !existsSync(tracesDir)) return { mode: 'allow' };

  // Security: traces dir must be inside project dir
  const canonicalProject = resolve(projectPath('.'));
  const canonicalTraces = resolve(tracesDir);
  if (!canonicalTraces.startsWith(canonicalProject)) return { mode: 'allow' };

  const incomplete = findIncompleteTraces(tracesDir);
  if (incomplete.length === 0) return { mode: 'allow' };

  return {
    mode: 'notify',
    reason: 'Traces missing reflections.',
    systemMessage: `Trace reminder: ${incomplete.join(', ')} missing reflections section.`,
  };
}

function resolveTracesDir(configured: string | undefined, active: string): string {
  if (!configured) {
    return projectPath('.ai', 'projects', active, 'traces');
  }
  if (configured.startsWith('/')) return configured;
  return projectPath(configured);
}

function findIncompleteTraces(tracesDir: string): string[] {
  const now = Date.now();
  const incomplete: string[] = [];

  try {
    const files = readdirSync(tracesDir).filter((f) => f.endsWith('.yml'));
    for (const file of files) {
      const filePath = join(tracesDir, file);
      const stat = statSync(filePath);

      // Only check files modified in the last 60 minutes
      if (now - stat.mtimeMs > RECENT_WINDOW_MS) continue;

      const content = readFileSync(filePath, 'utf-8');
      if (!content.includes('reflections:')) {
        // Extract skill name from filename (e.g., "skill-20260314T120000.yml" -> "skill")
        const skillName = basename(file).replace(/-\d{8}T.*\.yml$/, '');
        incomplete.push(skillName);
      }
    }
  } catch {
    // Fail silently
  }

  return incomplete;
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
