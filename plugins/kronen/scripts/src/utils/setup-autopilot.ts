import { projectPath } from '@kronen/hook-utils';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';

/**
 * Creates autopilot state file for in-session loop.
 * Called by the /kronen:autopilot-run command.
 */
export function setupAutopilot(args: string[]): void {
  const parsed = parseArgs(args);
  if (!parsed) return;

  const { prompt, maxIterations, completionPromise, dynamicPlan } = parsed;
  const sessionId = (process.env['CLAUDE_SESSION_ID'] ?? '').replace(/[^a-zA-Z0-9_-]/g, '') || 'unknown';
  const stateFile = projectPath('.claude', `autopilot-${sessionId}.local.md`);

  mkdirSync(dirname(stateFile), { recursive: true });

  const promiseYaml = completionPromise ? `"${completionPromise}"` : 'null';
  const planYaml = dynamicPlan ? `"${dynamicPlan}"` : 'null';
  const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

  const content = [
    '---',
    'active: true',
    'iteration: 1',
    `max_iterations: ${maxIterations}`,
    `completion_promise: ${promiseYaml}`,
    `dynamic_plan: ${planYaml}`,
    `started_at: "${timestamp}"`,
    '---',
    '',
    prompt,
    '',
  ].join('\n');

  writeFileSync(stateFile, content);

  // Output setup message
  const maxDisplay = maxIterations > 0 ? String(maxIterations) : 'unlimited';
  const promiseDisplay = completionPromise ? `${completionPromise} (output ONLY when TRUE)` : 'none';
  const planNote = dynamicPlan
    ? `Dynamic plan linked: ${dynamicPlan}\nEach iteration constructs a fresh prompt from the plan's state and learnings.`
    : 'When you try to exit, the SAME PROMPT will be fed back.\nPrevious work persists in files, creating a self-referential loop.';

  console.log(`Autopilot loop activated.

Iteration: 1
Max iterations: ${maxDisplay}
Completion promise: ${promiseDisplay}

The stop hook is now active. ${planNote}

To monitor: head -10 ${stateFile}
To cancel:  /kronen:autopilot-cancel`);

  console.log(`\n${prompt}`);

  if (completionPromise) {
    console.log(`
---
COMPLETION PROMISE
---

To complete this loop, output this EXACT text:
  <promise>${completionPromise}</promise>

REQUIREMENTS:
  - Use <promise> XML tags exactly as shown
  - The statement MUST be completely and unequivocally TRUE
  - Do NOT output false statements to exit the loop
  - If stuck, keep iterating — do not lie to escape
---`);
  }
}

interface ParsedArgs {
  prompt: string;
  maxIterations: number;
  completionPromise: string;
  dynamicPlan: string;
}

function parseArgs(args: string[]): ParsedArgs | null {
  const promptParts: string[] = [];
  let maxIterations = 50;
  let completionPromise = '';
  let dynamicPlan = '';

  let i = 0;
  while (i < args.length) {
    const arg = args[i];
    switch (arg) {
      case '--max-iterations':
        if (!args[i + 1] || !/^\d+$/.test(args[i + 1])) {
          process.stderr.write('Error: --max-iterations requires a number\n');
          process.exit(1);
        }
        maxIterations = parseInt(args[i + 1], 10);
        i += 2;
        break;
      case '--completion-promise':
        if (!args[i + 1]) {
          process.stderr.write('Error: --completion-promise requires text\n');
          process.exit(1);
        }
        completionPromise = args[i + 1];
        i += 2;
        break;
      case '--dynamic-plan':
        if (!args[i + 1]) {
          process.stderr.write('Error: --dynamic-plan requires a path\n');
          process.exit(1);
        }
        if (!existsSync(`${args[i + 1]}/state.yml`)) {
          process.stderr.write(`Error: no state.yml found at ${args[i + 1]}/state.yml\n`);
          process.exit(1);
        }
        dynamicPlan = args[i + 1];
        i += 2;
        break;
      case '-h':
      case '--help':
        console.log('Usage: setup-autopilot [PROMPT...] [--max-iterations N] [--completion-promise TEXT] [--dynamic-plan PATH]');
        process.exit(0);
        break;
      default:
        promptParts.push(arg);
        i++;
    }
  }

  let prompt = promptParts.join(' ');
  if (!prompt && !dynamicPlan) {
    process.stderr.write('Error: No prompt provided\n');
    process.exit(1);
  }
  if (!prompt && dynamicPlan) {
    prompt = `Execute the next cycle of the dynamic plan at ${dynamicPlan}`;
  }

  // Auto-detect completion promise from prompt
  if (!completionPromise) {
    const match = /<promise>([\s\S]*?)<\/promise>/.exec(prompt);
    if (match) {
      completionPromise = match[1].trim();
      console.log(`Auto-detected completion promise: "${completionPromise}"\n`);
    }
  }

  return { prompt, maxIterations, completionPromise, dynamicPlan };
}

// CLI entry point
if (!process.env['VITEST']) {
  setupAutopilot(process.argv.slice(2));
}
