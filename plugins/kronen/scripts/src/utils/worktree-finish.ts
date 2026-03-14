import { existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

type Action = 'merge' | 'pr' | 'keep' | 'discard';

/**
 * Handles worktree completion with four actions:
 * - merge: remove worktree, merge branch with --no-ff
 * - pr: push branch, remove worktree, create GitHub PR
 * - keep: remove worktree, keep branch
 * - discard: force-remove worktree, delete branch
 */
export function finishWorktree(name: string, action: string): void {
  if (!name || !action) {
    process.stderr.write('Usage: worktree-finish <name> merge|pr|keep|discard\n');
    process.exit(1);
  }

  const worktreeDir = `.worktrees/${name}`;
  if (!existsSync(worktreeDir)) {
    process.stderr.write(`Error: worktree '${worktreeDir}' not found.\n`);
    try {
      const list = execFileSync('git', ['worktree', 'list'], { encoding: 'utf-8' });
      process.stderr.write('Active worktrees:\n' + list);
    } catch { /* skip */ }
    process.exit(1);
  }

  const validActions: Action[] = ['merge', 'pr', 'keep', 'discard'];
  if (!validActions.includes(action as Action)) {
    process.stderr.write(`Error: unknown action '${action}'. Use: merge | pr | keep | discard\n`);
    process.exit(1);
  }

  let branch: string;
  try {
    branch = execFileSync('git', ['-C', worktreeDir, 'rev-parse', '--abbrev-ref', 'HEAD'], { encoding: 'utf-8' }).trim();
  } catch {
    process.stderr.write(`Error: could not determine branch for worktree '${name}'.\n`);
    process.exit(1);
    return; // unreachable but satisfies TS
  }

  console.log(`Finishing worktree '${name}' (branch: ${branch}) with action: ${action}`);

  switch (action as Action) {
    case 'merge': {
      const mainBranch = execFileSync('git', ['rev-parse', '--abbrev-ref', 'HEAD'], { encoding: 'utf-8' }).trim();
      console.log(`Merging '${branch}' into '${mainBranch}'...`);
      removeWorktree(worktreeDir);
      execFileSync('git', ['merge', branch, '--no-ff', '-m', `Merge branch '${branch}'`], { stdio: 'inherit' });
      console.log(`Merged. Branch '${branch}' still exists (delete with: git branch -d ${branch}).`);
      break;
    }

    case 'pr':
      console.log(`Pushing branch '${branch}' to remote...`);
      execFileSync('git', ['-C', worktreeDir, 'push', '-u', 'origin', branch], { stdio: 'inherit' });
      removeWorktree(worktreeDir);
      console.log('Creating pull request...');
      execFileSync('gh', ['pr', 'create', '--head', branch, '--fill'], { stdio: 'inherit' });
      break;

    case 'keep':
      try {
        execFileSync('git', ['worktree', 'remove', worktreeDir]);
      } catch {
        process.stderr.write("Worktree has uncommitted changes. Use 'discard' to force-remove, or commit first.\n");
        process.exit(1);
      }
      console.log(`Worktree removed. Branch '${branch}' kept.`);
      console.log(`Resume with: git worktree add .worktrees/${name} ${branch}`);
      break;

    case 'discard': {
      console.log(`Discarding worktree and branch '${branch}'...`);
      try { execFileSync('git', ['worktree', 'remove', worktreeDir, '--force']); } catch { /* skip */ }

      const mainRef = execFileSync('git', ['rev-parse', '--abbrev-ref', 'HEAD'], { encoding: 'utf-8' }).trim();
      try {
        execFileSync('git', ['merge-base', '--is-ancestor', branch, mainRef]);
      } catch {
        console.log(`Warning: branch '${branch}' has unmerged commits not in '${mainRef}'.`);
        console.log('Proceeding with delete as requested (discard action).');
      }

      try { execFileSync('git', ['branch', '-D', branch]); } catch {
        console.log(`Branch '${branch}' already deleted or not found.`);
      }
      console.log('Discarded.');
      break;
    }
  }

  try { execFileSync('git', ['worktree', 'prune']); } catch { /* skip */ }
  console.log('Done.');
}

function removeWorktree(dir: string): void {
  try {
    execFileSync('git', ['worktree', 'remove', dir]);
  } catch {
    execFileSync('git', ['worktree', 'remove', dir, '--force']);
  }
}

// CLI entry point
if (!process.env['VITEST']) {
  finishWorktree(process.argv[2] ?? '', process.argv[3] ?? '');
}
