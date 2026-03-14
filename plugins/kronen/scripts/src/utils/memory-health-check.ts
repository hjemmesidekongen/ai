import { homeDir } from '@kronen/hook-utils';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const LINE_CAP = 150;
const STALE_DAYS = 30;

/**
 * Read-only MEMORY.md health check. Outputs a human-readable report.
 * Checks: line count vs cap, stale entries (>30 days), graduation candidates.
 * Never modifies files.
 */
export function runHealthCheck(): string {
  const memoryFile = locateMemoryFile();
  const lines: string[] = ['', 'Memory Health Report', '==================='];

  if (!memoryFile) {
    lines.push('File: not found');
    lines.push('Status: No MEMORY.md found. Nothing to check.');
    return lines.join('\n');
  }

  lines.push(`File: ${memoryFile}`);

  const content = readFileSync(memoryFile, 'utf-8');
  const fileLines = content.split('\n');
  const lineCount = fileLines.length;

  // Line count status
  let statusMsg: string;
  if (lineCount < 100) statusMsg = 'healthy';
  else if (lineCount <= 130) statusMsg = 'growing -- consider pruning';
  else if (lineCount < LINE_CAP) statusMsg = 'near limit -- prune soon';
  else statusMsg = 'OVER LIMIT -- must prune now';

  lines.push(`Lines: ${lineCount}/${LINE_CAP} -- ${statusMsg}`);
  lines.push('');

  // Stale entry detection
  const staleEntries = findStaleEntries(fileLines);
  if (staleEntries.length > 0) {
    lines.push('Potentially stale (>30 days old):');
    for (const entry of staleEntries) {
      lines.push(`  Line ${entry.lineNum}: "${entry.text}"`);
    }
  } else {
    lines.push('Potentially stale: none found');
  }
  lines.push('');

  // Graduation candidates
  const gradCandidates = findGraduationCandidates(fileLines);
  if (gradCandidates.length > 0) {
    lines.push('Possible graduation candidates:');
    for (const entry of gradCandidates) {
      lines.push(`  Line ${entry.lineNum}: "${entry.text}" -> ${entry.reason}`);
    }
  } else {
    lines.push('Graduation candidates: none found');
  }
  lines.push('');

  // Action summary
  if (staleEntries.length > 0 || gradCandidates.length > 0 || lineCount >= 100) {
    lines.push('Action needed: Review flagged lines. Delete stale entries, graduate rules to CLAUDE.md.');
  } else {
    lines.push('No action needed. Memory is clean.');
  }
  lines.push('');

  return lines.join('\n');
}

function locateMemoryFile(): string | null {
  const home = homeDir();
  if (!home) return null;

  const workspace = process.env['CLAUDE_WORKSPACE'] ?? process.cwd();
  const encodedPath = workspace.replace(/\//g, '-');
  const primary = join(home, '.claude', 'projects', encodedPath, 'memory', 'MEMORY.md');
  if (existsSync(primary)) return primary;

  // Try without leading dash
  const altEncoded = workspace.replace(/^\//, '').replace(/\//g, '-');
  const alt = join(home, '.claude', 'projects', altEncoded, 'memory', 'MEMORY.md');
  if (existsSync(alt)) return alt;

  return null;
}

interface FlaggedEntry {
  lineNum: number;
  text: string;
  reason?: string;
}

function findStaleEntries(lines: string[]): FlaggedEntry[] {
  const cutoff = Date.now() - STALE_DAYS * 24 * 60 * 60 * 1000;
  const datePattern = /\d{4}-\d{2}-\d{2}/g;
  const entries: FlaggedEntry[] = [];

  for (let i = 0; i < lines.length; i++) {
    const matches = lines[i].match(datePattern);
    if (!matches) continue;

    for (const dateStr of matches) {
      const dateMs = new Date(dateStr).getTime();
      if (!isNaN(dateMs) && dateMs < cutoff) {
        entries.push({ lineNum: i + 1, text: lines[i].trim() });
        break;
      }
    }
  }

  return entries;
}

function findGraduationCandidates(lines: string[]): FlaggedEntry[] {
  const entries: FlaggedEntry[] = [];

  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    if (trimmed.startsWith('(Instruction preferences stored in')) continue;

    let reason = '';

    // Rule-like patterns: list items with always/never/prefer
    if (/^\s*-\s/.test(lines[i]) && /\b(always|never|prefer)\b/i.test(lines[i])) {
      reason = 'could be a CLAUDE.md rule';
    }

    // Mentions of skills, rules, or CLAUDE.md
    if (!reason && /\b(skill|CLAUDE\.md|rule)\b/i.test(lines[i])) {
      reason = 'mentions skill/rule/CLAUDE.md -- may have graduated';
    }

    if (reason) {
      entries.push({ lineNum: i + 1, text: trimmed, reason });
    }
  }

  return entries;
}
