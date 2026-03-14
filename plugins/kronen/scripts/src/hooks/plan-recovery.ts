import { createRunner, projectPath } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

interface ActivePlan {
  name: string;
  cycle: string;
  remaining: string;
  updatedAt: string;
}

/**
 * SessionStart hook: detects interrupted plans and surfaces them so the user
 * or autopilot can resume. Informational only — never modifies state.
 */
export function evaluate(_input: HookInput): HookResult {
  const plansDir = projectPath('.ai', 'plans');
  if (!existsSync(plansDir)) return { mode: 'allow' };

  const activePlans = findActivePlans(plansDir);
  if (activePlans.length === 0) return { mode: 'allow' };

  const message = formatPlanSummary(activePlans);
  return { mode: 'warn', message };
}

function findActivePlans(plansDir: string): ActivePlan[] {
  const plans: ActivePlan[] = [];

  try {
    const entries = readdirSync(plansDir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const stateFile = join(plansDir, entry.name, 'state.yml');
      if (!existsSync(stateFile)) continue;

      const content = readFileSync(stateFile, 'utf-8');
      const status = extractYamlField(content, 'status');
      if (status !== 'in_progress') continue;

      let remaining = extractYamlField(content, 'remaining_goal');
      if (remaining.length > 80) remaining = remaining.slice(0, 77) + '...';

      plans.push({
        name: extractYamlField(content, 'plan'),
        cycle: extractYamlField(content, 'cycle'),
        remaining,
        updatedAt: extractYamlField(content, 'updated_at'),
      });
    }
  } catch {
    // Fail silently
  }

  return plans;
}

function extractYamlField(content: string, field: string): string {
  const regex = new RegExp(`^${field}:\\s*(.+)$`, 'm');
  const match = regex.exec(content);
  if (!match) return '';
  return match[1].replace(/^["']|["']$/g, '').trim();
}

function formatPlanSummary(plans: ActivePlan[]): string {
  let output = 'Active plans detected:\n';
  for (const plan of plans) {
    output += `  - ${plan.name}: cycle ${plan.cycle}, remaining: ${plan.remaining}\n`;
    output += `    Last updated: ${plan.updatedAt}\n`;
    output += `    Resume with: /plan resume ${plan.name}\n`;
  }
  return output;
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
