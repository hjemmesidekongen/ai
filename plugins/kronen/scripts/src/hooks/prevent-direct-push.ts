import { createRunner } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';

const PROTECTED_BRANCHES = ['main', 'master', 'production'];

/**
 * PreToolUse hook (Bash): blocks git push to protected branches.
 * Protected: main, master, production, release/*
 * Allows push to feature branches and push with -u (setting upstream).
 */
export function evaluate(input: HookInput): HookResult {
  const toolInput = input.tool_input;
  const command = typeof toolInput?.command === 'string' ? toolInput.command : '';

  if (!command || !command.includes('git push')) {
    return { mode: 'allow' };
  }

  const isForce = /--force\b|-f\b/.test(command);

  // Extract everything after "git push" for branch detection
  const afterPush = command.slice(command.indexOf('git push') + 'git push'.length);

  // Check release/* pattern
  if (/\brelease\//.test(afterPush)) {
    return {
      mode: 'block',
      reason: isForce
        ? 'Force push to release branch is blocked. Use a PR workflow instead.'
        : 'Direct push to release branch is blocked. Use a PR workflow instead.',
    };
  }

  // Check protected branches — matches "main", "origin main", "HEAD:main", etc.
  for (const branch of PROTECTED_BRANCHES) {
    const asBranch = new RegExp(`\\b${branch}\\b`);
    const asRefspec = new RegExp(`:${branch}\\b`);

    if (asBranch.test(afterPush) || asRefspec.test(afterPush)) {
      if (isForce) {
        return {
          mode: 'block',
          reason: `Force push to protected branch ${branch} is blocked. Use a PR workflow instead.`,
        };
      }
      return {
        mode: 'block',
        reason: `Direct push to ${branch} is blocked. Push to a feature branch and create a PR instead.`,
      };
    }
  }

  return { mode: 'allow' };
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
