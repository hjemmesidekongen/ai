import { createRunner, projectDir } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { execFileSync } from 'node:child_process';

const INFRA_PATTERN = /plugins\/.+\/(skills|commands|scripts|agents|hooks|\.claude-plugin)\//;
const DOC_PATTERN = /(CLAUDE\.md|MEMORY\.md|roadmap\.yml|README\.md|ecosystem\.json)/;

/**
 * Stop hook: warns when plugin infrastructure files changed but no documentation
 * files were updated. Advisory only — never blocks.
 */
export function evaluate(_input: HookInput): HookResult {
  const changedFiles = getChangedFiles();
  if (changedFiles.length === 0) return { mode: 'allow' };

  const infraFiles = changedFiles.filter((f) => INFRA_PATTERN.test(f));
  if (infraFiles.length <= 1) return { mode: 'allow' };

  const hasDocChanges = changedFiles.some((f) => DOC_PATTERN.test(f));
  if (hasDocChanges) return { mode: 'allow' };

  return {
    mode: 'notify',
    reason: 'Doc drift detected.',
    systemMessage: `Doc drift warning: ${infraFiles.length} plugin files changed but no docs updated. Run doc-checkpoint skill.`,
  };
}

function getChangedFiles(): string[] {
  try {
    const cwd = projectDir();
    const unstaged = execFileSync('git', ['diff', '--name-only', 'HEAD'], { cwd, encoding: 'utf-8' });
    const staged = execFileSync('git', ['diff', '--cached', '--name-only'], { cwd, encoding: 'utf-8' });
    const combined = `${unstaged}\n${staged}`;
    return [...new Set(
      combined.split('\n').map((l) => l.trim()).filter((l) => l.length > 0),
    )];
  } catch {
    return [];
  }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
