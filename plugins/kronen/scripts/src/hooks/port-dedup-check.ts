import { createRunner, projectPath } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const COMPONENT_TYPES = ['skills', 'commands', 'agents'] as const;

/**
 * Stop hook: scans ecosystem.json files across all plugins and warns if any
 * skill, command, or agent name is registered in multiple plugins.
 * Advisory only — never blocks.
 */
export function evaluate(_input: HookInput): HookResult {
  const pluginsDir = projectPath('plugins');
  if (!existsSync(pluginsDir)) return { mode: 'allow' };

  const components = collectComponents(pluginsDir);
  const duplicates = findDuplicates(components);

  if (duplicates.length === 0) return { mode: 'allow' };

  return {
    mode: 'notify',
    reason: 'Duplicate components detected.',
    systemMessage: `Port dedup warning: ${duplicates.join('; ')}. Consider removing duplicates.`,
  };
}

function collectComponents(pluginsDir: string): Map<string, string[]> {
  const components = new Map<string, string[]>();

  try {
    const plugins = readdirSync(pluginsDir, { withFileTypes: true });
    for (const plugin of plugins) {
      if (!plugin.isDirectory()) continue;
      const ecosystemPath = join(pluginsDir, plugin.name, '.claude-plugin', 'ecosystem.json');
      if (!existsSync(ecosystemPath)) continue;

      try {
        const data = JSON.parse(readFileSync(ecosystemPath, 'utf-8')) as Record<string, unknown>;
        for (const kind of COMPONENT_TYPES) {
          const names = data[kind];
          if (!Array.isArray(names)) continue;
          for (const name of names) {
            if (typeof name !== 'string') continue;
            const key = `${kind}:${name}`;
            const existing = components.get(key) ?? [];
            existing.push(plugin.name);
            components.set(key, existing);
          }
        }
      } catch {
        // Skip malformed files
      }
    }
  } catch {
    // Fail silently
  }

  return components;
}

function findDuplicates(components: Map<string, string[]>): string[] {
  const duplicates: string[] = [];
  for (const [key, plugins] of components) {
    if (plugins.length > 1) {
      duplicates.push(`${key} in [${plugins.join(', ')}]`);
    }
  }
  return duplicates;
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
