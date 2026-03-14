import { readFileSync } from 'node:fs';
import yaml from 'js-yaml';

/**
 * Read and parse a YAML file. Returns null if file doesn't exist or can't be parsed.
 * Cross-platform — uses Node.js fs, no shell commands.
 */
export function parseYamlFile<T = Record<string, unknown>>(filePath: string): T | null {
  try {
    const content = readFileSync(filePath, 'utf-8');
    return yaml.load(content) as T;
  } catch {
    return null;
  }
}
