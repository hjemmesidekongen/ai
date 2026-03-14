import { createRunner, projectPath, parseYamlFile } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readdirSync, readFileSync, unlinkSync, appendFileSync, statSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';
import { assembleContext } from '../utils/assemble-context.ts';

const SNAPSHOT_MAX_AGE_MS = 48 * 60 * 60 * 1000; // 48 hours
const AUTOPILOT_MAX_AGE_MS = 24 * 60 * 60 * 1000; // 24 hours

/**
 * SessionStart hook: refreshes snapshot, cleans stale files, outputs context.
 * 1. Exports session_id to CLAUDE_ENV_FILE
 * 2. Deletes snapshots older than 48h
 * 3. Cleans stale autopilot files (>24h)
 * 4. Refreshes snapshot via assembler
 * 5. Outputs snapshot + recovery info
 */
export function evaluate(input: HookInput): HookResult {
  exportSessionId(input);
  cleanStaleFiles();
  assembleContext('session-start');

  const output = buildRecoveryOutput();
  if (output) {
    return { mode: 'warn', message: output };
  }
  return { mode: 'allow' };
}

function exportSessionId(input: HookInput): void {
  const sessionId = typeof input.session_id === 'string'
    ? input.session_id.replace(/[^a-zA-Z0-9_-]/g, '')
    : '';
  const envFile = process.env['CLAUDE_ENV_FILE'];
  if (sessionId && envFile) {
    try {
      mkdirSync(dirname(envFile), { recursive: true });
      appendFileSync(envFile, `export CLAUDE_SESSION_ID=${sessionId}\n`);
    } catch { /* best-effort */ }
  }
}

function cleanStaleFiles(): void {
  const now = Date.now();

  // Delete old snapshots
  const snapshotPath = projectPath('.ai', 'context', 'snapshot.yml');
  if (existsSync(snapshotPath)) {
    try {
      const age = now - statSync(snapshotPath).mtimeMs;
      if (age > SNAPSHOT_MAX_AGE_MS) unlinkSync(snapshotPath);
    } catch { /* skip */ }
  }

  // Clean stale autopilot files
  const claudeDir = projectPath('.claude');
  if (existsSync(claudeDir)) {
    try {
      for (const file of readdirSync(claudeDir)) {
        if (!file.startsWith('autopilot-') || !file.endsWith('.local.md')) continue;
        const filePath = join(claudeDir, file);
        try {
          const age = now - statSync(filePath).mtimeMs;
          if (age > AUTOPILOT_MAX_AGE_MS) unlinkSync(filePath);
        } catch { /* skip */ }
      }
      // Legacy cleanup
      const legacy = join(claudeDir, 'autopilot.local.md');
      if (existsSync(legacy)) unlinkSync(legacy);
    } catch { /* skip */ }
  }

}

function buildRecoveryOutput(): string | null {
  const lines: string[] = [];

  // Output snapshot if exists — remove compact flag only if snapshot is available
  const snapshotPath = projectPath('.ai', 'context', 'snapshot.yml');
  if (existsSync(snapshotPath)) {
    try {
      lines.push('=== Context Snapshot ===');
      lines.push(readFileSync(snapshotPath, 'utf-8').trim());
      lines.push('=== End Snapshot ===');
      // Remove compact-needed flag — context is fresh
      const flag = projectPath('.ai', 'compact-needed');
      if (existsSync(flag)) {
        try { unlinkSync(flag); } catch { /* skip */ }
      }
    } catch { /* skip */ }
  }

  lines.push('=== Session Recovery Check ===');
  let foundContext = false;

  // Check active plans
  const plansDir = projectPath('.ai', 'plans');
  if (existsSync(plansDir)) {
    try {
      for (const entry of readdirSync(plansDir, { withFileTypes: true })) {
        if (!entry.isDirectory()) continue;
        const stateFile = join(plansDir, entry.name, 'state.yml');
        if (!existsSync(stateFile)) continue;
        const state = parseYamlFile<Record<string, unknown>>(stateFile);
        if (state?.status !== 'in_progress') continue;

        const plan = typeof state.plan === 'string' ? state.plan : entry.name;
        const wave = typeof state.current_wave === 'string' ? state.current_wave : '';
        const task = typeof state.current_task === 'string' ? state.current_task : '';
        lines.push(`Active plan: ${plan} (wave: ${wave}, task: ${task})`);

        const content = readFileSync(stateFile, 'utf-8');
        const errorCount = (content.match(/ {2}- timestamp:/g) ?? []).length;
        if (errorCount > 0) lines.push(`  Logged errors: ${errorCount}`);
        foundContext = true;
      }
    } catch { /* skip */ }
  }

  // Check active agency project
  const agencyFile = projectPath('.ai', 'agency.yml');
  if (existsSync(agencyFile)) {
    const agency = parseYamlFile<{ active?: string }>(agencyFile);
    if (agency?.active) {
      const stateFile = projectPath('.ai', 'projects', agency.active, 'state.yml');
      if (existsSync(stateFile)) {
        lines.push(`Active project: ${agency.active}`);
        lines.push('--- Project State ---');
        const content = readFileSync(stateFile, 'utf-8');
        lines.push(content.split('\n').slice(0, 30).join('\n'));
        foundContext = true;
      }
    }
  }

  if (!foundContext) lines.push('No state.yml found. Fresh start.');

  // Git status
  lines.push('--- Git Status ---');
  try {
    const status = execFileSync('git', ['status', '--short'], {
      cwd: projectPath('.'),
      encoding: 'utf-8',
      timeout: 5000,
    });
    lines.push(status.split('\n').slice(0, 20).join('\n'));
  } catch {
    lines.push('(git not available)');
  }

  lines.push('=== End Recovery ===');
  return lines.join('\n');
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
