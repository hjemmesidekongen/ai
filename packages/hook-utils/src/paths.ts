import { tmpdir } from 'node:os';
import { join } from 'node:path';

/** Project root directory — uses CLAUDE_PROJECT_DIR env var, falls back to cwd. */
export function projectDir(): string {
  return process.env['CLAUDE_PROJECT_DIR'] ?? process.cwd();
}

/** Plugin root directory — uses CLAUDE_PLUGIN_ROOT env var. */
export function pluginRoot(): string {
  return process.env['CLAUDE_PLUGIN_ROOT'] ?? '';
}

/** Cross-platform temp directory. */
export function tempDir(): string {
  return tmpdir();
}

/** Join paths relative to the project directory. */
export function projectPath(...segments: string[]): string {
  return join(projectDir(), ...segments);
}

/** Join paths relative to the plugin root. */
export function pluginPath(...segments: string[]): string {
  return join(pluginRoot(), ...segments);
}

/** User home directory — cross-platform. */
export function homeDir(): string {
  return process.env['HOME'] ?? process.env['USERPROFILE'] ?? '';
}
