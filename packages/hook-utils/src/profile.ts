import { readFileSync } from 'node:fs';
import { projectPath } from './paths.ts';

/**
 * Read the kronen profile cache and return flag values.
 * The cache file contains KEY=value lines like KRONEN_TRACING=light.
 * Returns a Map of flag names to values. Returns empty map if file doesn't exist.
 */
export function readProfileCache(): Map<string, string> {
  const flags = new Map<string, string>();
  try {
    const content = readFileSync(projectPath('.ai', 'context', 'kronen-profile-cache'), 'utf-8');
    for (const line of content.split('\n')) {
      const match = /^(KRONEN_[A-Z_]+)=(.+)$/.exec(line);
      if (match) {
        flags.set(match[1], match[2]);
      }
    }
  } catch {
    // Cache doesn't exist — return defaults
  }
  return flags;
}

/** Check if tracing is disabled in the profile cache. */
export function isTracingDisabled(): boolean {
  const flags = readProfileCache();
  return flags.get('KRONEN_TRACING') === 'disabled';
}
