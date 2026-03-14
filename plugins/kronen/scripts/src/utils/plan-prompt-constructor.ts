import { projectPath, parseYamlFile } from '@kronen/hook-utils';
import { existsSync } from 'node:fs';
import { basename, join } from 'node:path';

interface PlanState {
  cycle?: number;
  goal?: string;
  remaining_goal?: string;
  replan_count?: number;
  max_cycles?: number;
  status?: string;
}

interface Learnings {
  entries?: Array<{ status?: string }>;
  open_questions?: string[];
  next_orientation?: string;
}

/**
 * Reads a plan's state.yml + learnings.yml and constructs a cycle-aware
 * prompt for the autopilot stop hook. Returns empty string when plan is done.
 */
export function constructPlanPrompt(planDir: string): string {
  const resolvedDir = planDir.startsWith('/') ? planDir : projectPath(planDir);
  const stateFile = join(resolvedDir, 'state.yml');

  if (!existsSync(stateFile)) return '';

  const state = parseYamlFile<PlanState>(stateFile);
  if (!state?.goal) return '';

  const cycle = state.cycle ?? 1;
  const goal = state.goal;
  const remaining = state.remaining_goal ?? '(not yet assessed)';
  const replanCount = state.replan_count ?? 0;
  const maxCycles = state.max_cycles ?? 15;
  const status = state.status ?? 'active';

  // Plan is done
  if (status === 'done') return '';

  // Max cycles reached — escalate
  if (cycle >= maxCycles) {
    return [
      `Plan: ${basename(resolvedDir)} — ESCALATE (max cycles reached)`,
      '',
      `Goal: ${goal}`,
      `Cycles completed: ${cycle} / ${maxCycles}`,
      '',
      'Max cycles reached. This plan needs human review.',
      `Read ${stateFile} and ${join(resolvedDir, 'learnings.yml')}, summarize progress, and report what's done vs remaining.`,
      'Do NOT start another cycle. Set status to "escalated" in state.yml.',
    ].join('\n');
  }

  // Read learnings
  const learningsFile = join(resolvedDir, 'learnings.yml');
  let activeCount = 0;
  let questionCount = 0;
  let nextOrientation = '';

  if (existsSync(learningsFile)) {
    const learnings = parseYamlFile<Learnings>(learningsFile);
    if (learnings) {
      activeCount = (learnings.entries ?? []).filter((e) => e.status === 'active').length;
      questionCount = (learnings.open_questions ?? []).length;
      nextOrientation = learnings.next_orientation ?? '';
    }
  }

  const nextCycle = cycle + 1;
  const planName = basename(resolvedDir);

  const lines = [
    `Plan: ${planName} — Cycle ${nextCycle}`,
    '',
    `Goal: ${goal}`,
    `Remaining: ${remaining}`,
    `Learnings: ${activeCount} active, ${questionCount} open questions`,
    `Replans used: ${replanCount} / 2`,
  ];

  if (nextOrientation) {
    lines.push(`Next orientation: ${nextOrientation}`);
  }

  lines.push(
    '',
    'Continue the planning loop:',
    `1. Read ${resolvedDir}/state.yml and ${resolvedDir}/learnings.yml`,
    '2. Read plugins/kronen/skills/plan-engine/references/process.md for the full algorithm',
    '3. Run the REFLECT phase — classify as CONTINUE/ADJUST/REPLAN/ESCALATE',
    '4. Based on classification, run the appropriate next step (plan next wave, replan, or escalate)',
    '5. Execute the wave',
    '6. Run the LEARN phase — record learnings, update remaining_goal, increment cycle',
    '7. If goal is met, set status to done',
    '',
    'If you need human input for scope changes or cost decisions, ESCALATE immediately.',
  );

  return lines.join('\n');
}

// CLI entry point
if (!process.env['VITEST']) {
  const planDir = process.argv[2];
  if (!planDir) {
    process.stderr.write('Usage: plan-prompt-constructor <plan-directory>\n');
    process.exit(1);
  }
  const prompt = constructPlanPrompt(planDir);
  if (prompt) process.stdout.write(prompt + '\n');
}
