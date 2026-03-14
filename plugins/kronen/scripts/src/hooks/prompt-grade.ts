import { createRunner, projectPath } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const INTERVENTION_MESSAGE = `Prompt quality: LOW clarity + HIGH stakes. Before executing, sharpen the prompt:
1. Identify what's vague (missing files, scope, constraints, success criteria)
2. Infer missing context from the codebase
3. Present: "I'll approach this as: [sharpened version]" and ask if that's right
Do NOT proceed with the vague version directly.`;

interface PromptGrade {
  clarity: number;
  stakes: number;
}

/**
 * UserPromptSubmit hook: scores prompts on clarity (0-10) and stakes (0-10).
 * When a prompt is vague AND high-stakes, outputs coaching to sharpen it first.
 * Non-blocking — always returns allow or warn.
 */
export function evaluate(input: HookInput): HookResult {
  const prompt = extractPrompt(input);
  if (!prompt || prompt.length < 5) return { mode: 'allow' };

  const { clarity, stakes } = gradePrompt(prompt);
  const shouldIntervene =
    (clarity <= 4 && stakes >= 6) || (clarity <= 6 && stakes >= 8);

  logDecision(prompt, clarity, stakes, shouldIntervene);

  if (shouldIntervene) {
    return { mode: 'warn', message: INTERVENTION_MESSAGE };
  }

  return { mode: 'allow' };
}

/** Exported for direct testing of scoring logic. */
export function gradePrompt(prompt: string): PromptGrade {
  return {
    clarity: scoreClarity(prompt),
    stakes: scoreStakes(prompt),
  };
}

function extractPrompt(input: HookInput): string | null {
  // Try user_prompt field first
  if (typeof input.user_prompt === 'string') return input.user_prompt;
  // Try nested prompt field
  if (typeof input['prompt'] === 'string') return input['prompt'];
  return null;
}

function scoreClarity(prompt: string): number {
  const lower = prompt.toLowerCase();
  let score = 0;

  // Word count contribution (0-3)
  const wordCount = prompt.split(/\s+/).filter((w) => w.length > 0).length;
  if (wordCount >= 31) score += 3;
  else if (wordCount >= 16) score += 2;
  else if (wordCount >= 6) score += 1;

  // File paths present (0-2)
  if (/\/\S+\.\S+/.test(prompt) || /\b(src|plugins|components|pages|lib)\//.test(prompt)) {
    score += 2;
  } else if (/\.(ts|js|py|sh|yml|json|md)\b/.test(prompt)) {
    score += 1;
  }

  // Action verbs (0-2)
  let actionScore = 0;
  if (/\b(add|create|remove|update|change|move|extract)\b/.test(lower)) actionScore++;
  if (/\b(replace|convert|split|merge|insert|wrap|rename)\b/.test(lower)) actionScore++;
  score += Math.min(actionScore, 2);

  // Constraints mentioned (0-2)
  let constraintScore = 0;
  if (/\b(must|should|only|without)\b/.test(lower) || /\bno more than\b|\bat most\b|\bat least\b/.test(lower)) constraintScore++;
  if (/\b(lines|characters|words|bytes|max|limit|under)\b/.test(lower)) constraintScore++;
  score += Math.min(constraintScore, 2);

  // Output format specs (0-1)
  if (/\b(json|yaml|csv|markdown|table|list|format|output)\b/.test(lower)) score++;

  return Math.min(score, 10);
}

function scoreStakes(prompt: string): number {
  const lower = prompt.toLowerCase();

  // High stakes (7-10)
  if (/\bdeploy\b|\bproduction\b/.test(lower)) return 10;
  if (/\barchitect\b|\bdesign system\b|\bmigrat(e|ion)\b|\bredesign\b|\brewrite\b|\bauthenticat(ion|e)\b|\bauth\b|\bsecurity\b/.test(lower)) return 9;
  if (/\brefactor\b|\binfrastructure\b|\bdatabase\b|\bschema\b/.test(lower)) return 8;
  if (/\bimplement\b|\bscaffold\b|\bbuild\b|\bapi\b|\bendpoint\b|\bcodebase\b|\beverything\b|\bentire\b|\bwhole project\b/.test(lower)) return 7;

  // Creative-high (7-8)
  if (/\blanding page\b|\blanding\b|\bbrand(ing)?\b/.test(lower)) return 8;
  if (/\bprofessional\b|\bpolished\b|\bbeautiful\b|\bstunning\b|\bportfolio\b|\bshowcase\b/.test(lower)) return 7;

  // Medium (4-6)
  if (/\bcomponent\b|\bfeature\b/.test(lower)) return 5;
  if (/\bhook\b|\bplugin\b/.test(lower)) return 5;
  if (/\btest\b|\bspec\b/.test(lower)) return 4;
  if (/\bconfig\b|\bsetup\b|\bstyle\b|\bcss\b/.test(lower)) return 4;

  // Low (1-3)
  if (/\bfix\b/.test(lower)) return 3;
  if (/\brename\b|\bdelete\b|\bremove\b|\bcheck\b/.test(lower)) return 2;
  if (/\bread\b|\blist\b|\bshow\b|\bstatus\b|\blog\b|\bprint\b/.test(lower)) return 1;

  // Default medium
  return 5;
}

function logDecision(prompt: string, clarity: number, stakes: number, intervened: boolean): void {
  try {
    const logPath = projectPath('.ai', 'traces', 'hook-errors.log');
    mkdirSync(dirname(logPath), { recursive: true });
    const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    const preview = prompt.slice(0, 80).replace(/[|\n\r]/g, '-');
    const decision = intervened ? 'intervene' : 'pass';
    const detail = intervened
      ? `clarity=${clarity} stakes=${stakes} — vague high-stakes prompt`
      : `clarity=${clarity} stakes=${stakes}`;
    appendFileSync(logPath, `${timestamp}|prompt-grade|${decision}|${preview}|${detail}\n`);
  } catch {
    // Best-effort logging
  }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
