import { projectPath, parseYamlFile } from '@kronen/hook-utils';
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { execFileSync } from 'node:child_process';

/**
 * Shared context assembler — builds .ai/context/snapshot.yml
 * with workspace, project, plan, and session trail layers.
 * Called by precompact-snapshot, session-context-stop, and session-recovery.
 */
export function assembleContext(source: string): void {
  try {
    const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    const workspace = gatherWorkspace();
    const project = gatherProject();
    const workingState = gatherWorkingState();
    const sessionTrail = gatherSessionTrail(workingState.planName);

    const snapshotPath = projectPath('.ai', 'context', 'snapshot.yml');
    mkdirSync(dirname(snapshotPath), { recursive: true });
    writeFileSync(snapshotPath, buildSnapshot(timestamp, source, workspace, project, workingState, sessionTrail));
  } catch {
    // Always succeed
  }
}

interface Workspace {
  branch: string;
  dirtyCount: number;
  identity: string;
}

interface Project {
  name: string | null;
  status: string;
  currentModule: string;
  completed: string;
}

interface WorkingState {
  planName: string;
  planWave: string;
  planTask: string;
  modifiedFiles: string[];
  errorCount: number;
}

interface SessionTrail {
  intent: string;
  decisionsModified: string[];
  nextStep: string;
}

function gatherWorkspace(): Workspace {
  let branch = 'unknown';
  let dirtyCount = 0;
  let identity = '';

  try {
    branch = execFileSync('git', ['rev-parse', '--abbrev-ref', 'HEAD'], {
      cwd: projectPath('.'),
      encoding: 'utf-8',
    }).trim();
  } catch { /* use default */ }

  try {
    const status = execFileSync('git', ['status', '--porcelain'], {
      cwd: projectPath('.'),
      encoding: 'utf-8',
    });
    dirtyCount = status.split('\n').filter((l) => l.length > 0).length;
  } catch { /* use default */ }

  const claudeMd = projectPath('CLAUDE.md');
  if (existsSync(claudeMd)) {
    try {
      const lines = readFileSync(claudeMd, 'utf-8').split('\n').slice(0, 5);
      const heading = lines.find((l) => l.startsWith('# '));
      if (heading) identity = heading.slice(2).trim();
    } catch { /* use default */ }
  }
  if (!identity) identity = basename(projectPath('.'));

  return { branch, dirtyCount, identity };
}

function gatherProject(): Project {
  const agencyFile = projectPath('.ai', 'agency.yml');
  if (!existsSync(agencyFile)) {
    return { name: null, status: '', currentModule: '', completed: '' };
  }

  const agency = parseYamlFile<{ active?: string }>(agencyFile);
  const activeName = agency?.active ?? null;
  if (!activeName) {
    return { name: null, status: '', currentModule: '', completed: '' };
  }

  const stateFile = projectPath('.ai', 'projects', activeName, 'state.yml');
  if (!existsSync(stateFile)) {
    return { name: activeName, status: 'unknown', currentModule: '', completed: '' };
  }

  const state = parseYamlFile<Record<string, unknown>>(stateFile);
  return {
    name: activeName,
    status: typeof state?.status === 'string' ? state.status : 'unknown',
    currentModule: typeof state?.current_module === 'string' ? state.current_module : '',
    completed: extractCompletedModules(state),
  };
}

function extractCompletedModules(state: Record<string, unknown> | null): string {
  if (!state?.modules || typeof state.modules !== 'object') return '';
  const modules = state.modules as Record<string, Record<string, unknown>>;
  return Object.entries(modules)
    .filter(([_, mod]) => mod?.status === 'completed')
    .map(([name]) => name)
    .join(', ');
}

function gatherWorkingState(): WorkingState {
  const result: WorkingState = {
    planName: '', planWave: '', planTask: '',
    modifiedFiles: [], errorCount: 0,
  };

  const plansDir = projectPath('.ai', 'plans');
  if (existsSync(plansDir)) {
    try {
      for (const entry of readdirSync(plansDir, { withFileTypes: true })) {
        if (!entry.isDirectory()) continue;
        const stateFile = join(plansDir, entry.name, 'state.yml');
        if (!existsSync(stateFile)) continue;

        const state = parseYamlFile<Record<string, unknown>>(stateFile);
        if (state?.status !== 'in_progress') continue;

        result.planName = typeof state.plan === 'string' ? state.plan : entry.name;
        result.planWave = typeof state.current_wave === 'string' ? state.current_wave : '';
        result.planTask = typeof state.current_task === 'string' ? state.current_task : '';
        result.errorCount = countErrors(stateFile);
        break;
      }
    } catch { /* skip */ }
  }

  result.modifiedFiles = extractModifiedFiles();
  return result;
}

function countErrors(stateFile: string): number {
  try {
    const content = readFileSync(stateFile, 'utf-8');
    return (content.match(/ {2}- timestamp:/g) ?? []).length;
  } catch {
    return 0;
  }
}

function extractModifiedFiles(): string[] {
  const traceFile = projectPath('.ai', 'traces', 'trace-light.log');
  if (!existsSync(traceFile)) return [];

  try {
    const content = readFileSync(traceFile, 'utf-8');
    const lines = content.trim().split('\n').slice(-20);
    const files = new Set<string>();

    for (const line of lines) {
      const parts = line.split('|');
      const tool = parts[1];
      const ctx = parts[3];
      if ((tool === 'Write' || tool === 'Edit') && ctx && ctx !== '-') {
        files.add(ctx);
      }
    }

    return [...files].slice(0, 10);
  } catch {
    return [];
  }
}

function gatherSessionTrail(planName: string): SessionTrail {
  let intent = 'No active plan or session';
  const decisionsModified: string[] = [];
  let nextStep = '';

  // Intent from plan doc
  if (planName) {
    const planDoc = projectPath('.ai', 'plans', planName, 'plan.md');
    if (existsSync(planDoc)) {
      try {
        const lines = readFileSync(planDoc, 'utf-8').split('\n');
        const heading = lines.find((l) => l.startsWith('# '));
        if (heading) intent = heading.slice(2).trim().slice(0, 80);
      } catch { /* skip */ }
    }
  }

  // Fallback: brainstorm topic
  if (intent === 'No active plan or session') {
    const brainstormDir = projectPath('.ai', 'brainstorm');
    if (existsSync(brainstormDir)) {
      try {
        const dirs = readdirSync(brainstormDir, { withFileTypes: true })
          .filter((d) => d.isDirectory());
        if (dirs.length > 0) intent = `Brainstorm: ${dirs[0].name}`;
      } catch { /* skip */ }
    }
  }

  // Decisions from trace-light
  const traceFile = projectPath('.ai', 'traces', 'trace-light.log');
  if (existsSync(traceFile)) {
    try {
      const content = readFileSync(traceFile, 'utf-8');
      const lines = content.trim().split('\n').slice(-100);
      const seen = new Set<string>();
      for (const line of lines) {
        const parts = line.split('|');
        const tool = parts[1];
        const ctx = parts[3];
        if ((tool === 'Write' || tool === 'Edit') && ctx?.includes('decision') && !seen.has(ctx)) {
          seen.add(ctx);
          decisionsModified.push(ctx);
          if (decisionsModified.length >= 5) break;
        }
      }
    } catch { /* skip */ }
  }

  // Next step from plan state
  if (planName) {
    const planState = projectPath('.ai', 'plans', planName, 'state.yml');
    if (existsSync(planState)) {
      try {
        const content = readFileSync(planState, 'utf-8');
        const pendingMatch = /name:\s*"?([^"\n]+)"?\s*\n\s*(?:.*\n)*?\s*status:\s*pending/m.exec(content);
        if (pendingMatch) nextStep = pendingMatch[1].trim();
      } catch { /* skip */ }
    }
  }

  return { intent, decisionsModified, nextStep };
}

function buildSnapshot(
  timestamp: string, source: string,
  ws: Workspace, proj: Project,
  state: WorkingState, trail: SessionTrail,
): string {
  const lines: string[] = [
    '# Session context — generated by assemble-context',
    `generated: "${timestamp}"`,
    `source: "${source}"`,
    '',
    'workspace:',
    `  branch: "${ws.branch}"`,
    `  dirty_files: ${ws.dirtyCount}`,
    `  identity: "${ws.identity}"`,
    '',
  ];

  if (proj.name) {
    lines.push('project:');
    lines.push(`  name: "${proj.name}"`);
    lines.push(`  status: "${proj.status}"`);
    lines.push(`  current_module: ${proj.currentModule || 'null'}`);
    lines.push(`  completed: [${proj.completed}]`);
  } else {
    lines.push('project: null');
  }

  lines.push('');
  lines.push('working_state:');
  if (state.planName) {
    lines.push(`  active_plan: "${state.planName} (${state.planWave}, ${state.planTask})"`);
  } else {
    lines.push('  active_plan: null');
  }

  if (state.modifiedFiles.length > 0) {
    lines.push('  modified_files:');
    for (const f of state.modifiedFiles) {
      lines.push(`    - ${f}`);
    }
  } else {
    lines.push('  modified_files: []');
  }
  lines.push(`  error_count: ${state.errorCount}`);

  lines.push('');
  lines.push('session_trail:');
  lines.push(`  intent: "${trail.intent}"`);

  if (trail.decisionsModified.length > 0) {
    lines.push('  decisions_modified:');
    for (const d of trail.decisionsModified) {
      lines.push(`    - ${d}`);
    }
  } else {
    lines.push('  decisions_modified: []');
  }

  lines.push(trail.nextStep ? `  next_step: "${trail.nextStep}"` : '  next_step: null');

  lines.push('');
  lines.push('probes:');
  if (state.planName) lines.push(`  - "Were you executing plan '${state.planName}'?"`);
  if (trail.intent !== 'No active plan or session') lines.push(`  - "Were you working on: ${trail.intent}?"`);
  if (state.modifiedFiles.length > 0) {
    const probe = basename(state.modifiedFiles[0]);
    lines.push(`  - "Did you modify files including '${probe}'?"`);
  }
  if (trail.nextStep) lines.push(`  - "Is your next step: ${trail.nextStep}?"`);
  lines.push('  - "Are there any blockers or errors to address?"');
  lines.push('');

  return lines.join('\n');
}
