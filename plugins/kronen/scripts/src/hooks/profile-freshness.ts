import { createRunner, projectPath, parseYamlFile } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

/** Workspace config files to hash for freshness checking. */
const CONFIG_FILES = [
  'package.json',
  'pnpm-workspace.yaml',
  'turbo.json',
  'tsconfig.json',
];

/**
 * SessionStart hook: checks if project profile (.ai/project-map.yml) is stale
 * by comparing a hash of workspace config files against the stored content_hash.
 * Outputs a one-line warning if stale. Never blocks, never auto-regenerates.
 */
export function evaluate(_input: HookInput): HookResult {
  const profilePath = projectPath('.ai', 'project-map.yml');
  if (!existsSync(profilePath)) return { mode: 'allow' };

  const profile = parseYamlFile<{ content_hash?: string }>(profilePath);
  const storedHash = profile?.content_hash;
  if (!storedHash) return { mode: 'allow' };

  const currentHash = computeConfigHash();
  if (!currentHash) return { mode: 'allow' };

  if (currentHash === storedHash) return { mode: 'allow' };

  return {
    mode: 'warn',
    message: 'Project profile may be stale. Workspace config files changed since last scan. Run /smedjen:dev-scan to refresh.',
  };
}

/** Compute SHA-256 of workspace config file contents. Exported for testing. */
export function computeConfigHash(): string {
  const parts: string[] = [];

  for (const file of CONFIG_FILES) {
    const filePath = projectPath(file);
    if (existsSync(filePath)) {
      try {
        parts.push(readFileSync(filePath, 'utf-8'));
      } catch {
        // Skip unreadable files
      }
    }
  }

  if (parts.length === 0) return '';
  return createHash('sha256').update(parts.join('\n')).digest('hex');
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
