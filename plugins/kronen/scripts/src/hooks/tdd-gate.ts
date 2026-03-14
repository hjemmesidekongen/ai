import { createRunner, projectPath } from '@kronen/hook-utils';
import type { HookInput, HookResult } from '@kronen/hook-utils';
import { existsSync, readdirSync, appendFileSync, mkdirSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { execFileSync } from 'node:child_process';

/** Production code extensions that require test files. */
const GATED_EXTENSIONS = new Set([
  'cs', 'py', 'ts', 'tsx', 'js', 'jsx', 'go', 'rs', 'rb', 'php', 'java', 'kt', 'swift', 'dart',
]);

/** Test file naming patterns to skip. */
const TEST_FILE_PATTERNS = [
  /Test\.\w+$/, /Tests\.\w+$/, /_test\.\w+$/, /^test_/,
  /\.test\.\w+$/, /\.spec\.\w+$/, /Spec\.\w+$/, /Specs\.\w+$/,
];

/** Non-production file patterns to skip. */
const SKIP_PATTERNS = [
  /Migration/i, /\.dto\./i, /DTO/,
  /Program\.cs$/, /Startup\.cs$/, /appsettings/i, /\.csproj$/, /\.sln$/,
  /\.d\.ts$/, /\.config\.(ts|js)$/, /tsconfig/, /package\.json$/,
  /Dockerfile/, /docker-compose/, /\.tf$/, /\.tfvars$/,
  /\.(yml|yaml|md|txt|json|xml|html|css|scss)$/,
];

/** Directories that indicate non-production code. */
const SKIP_DIRS = [
  /\/(test|tests|Test|Tests|__tests__)\//,
  /\/(spec|specs|fixtures|mocks|stubs)\//,
  /\/(migrations|seeds|config|scripts)\//,
];

/**
 * PreToolUse hook (Write|Edit): blocks production code writes without
 * a corresponding test file. Opt-out via CLAUDE_NO_TDD_GATE=1 env var
 * or .claude/no-tdd-gate file.
 */
export function evaluate(input: HookInput): HookResult {
  // Opt-out checks
  if (process.env['CLAUDE_NO_TDD_GATE'] === '1') return { mode: 'allow' };
  if (existsSync(projectPath('.claude', 'no-tdd-gate'))) return { mode: 'allow' };

  const filePath = extractFilePath(input);
  if (!filePath) return { mode: 'allow' };

  const ext = filePath.split('.').pop() ?? '';
  if (!GATED_EXTENSIONS.has(ext)) return { mode: 'allow' };

  const fileName = basename(filePath);

  // Skip test files
  if (TEST_FILE_PATTERNS.some((p) => p.test(fileName))) return { mode: 'allow' };

  // Skip non-production file patterns
  if (SKIP_PATTERNS.some((p) => p.test(fileName))) return { mode: 'allow' };

  // Skip non-production directories
  if (SKIP_DIRS.some((p) => p.test(filePath))) return { mode: 'allow' };

  const nameNoExt = fileName.replace(/\.\w+$/, '');
  const testFound = findTestFile(filePath, nameNoExt);

  if (!testFound) {
    logBlock(filePath, fileName);
    return {
      mode: 'block',
      reason: `TDD GATE: No test file found for ${fileName}. Create ${nameNoExt}.test.${ext} or ${nameNoExt}_test.${ext}. Opt-out: CLAUDE_NO_TDD_GATE=1`,
    };
  }

  return { mode: 'allow' };
}

function extractFilePath(input: HookInput): string | null {
  const toolInput = input.tool_input;
  if (!toolInput) return null;
  const filePath = toolInput.file_path;
  return typeof filePath === 'string' && filePath.length > 0 ? filePath : null;
}

function findTestFile(filePath: string, nameNoExt: string): boolean {
  const fileDir = dirname(filePath);
  const testPatterns = [
    `${nameNoExt}Test.`, `${nameNoExt}Tests.`, `${nameNoExt}.test.`,
    `${nameNoExt}.spec.`, `${nameNoExt}_test.`, `test_${nameNoExt}.`,
  ];

  // Search nearby directories first
  const nearbyDirs = [
    fileDir,
    join(fileDir, '..', 'test'), join(fileDir, '..', 'tests'),
    join(fileDir, '..', 'Test'), join(fileDir, '..', 'Tests'),
    join(fileDir, '..', '__tests__'),
    join(fileDir, '__tests__'),
  ];

  for (const dir of nearbyDirs) {
    if (!existsSync(dir)) continue;
    try {
      const files = readdirSync(dir);
      if (files.some((f) => testPatterns.some((p) => f.startsWith(p)))) {
        return true;
      }
    } catch {
      continue;
    }
  }

  // Fallback: project-wide search using find
  try {
    const projectRoot = getProjectRoot();
    const findArgs = [projectRoot, '-maxdepth', '6', '-type', 'f', '('];
    for (let i = 0; i < testPatterns.length; i++) {
      if (i > 0) findArgs.push('-o');
      findArgs.push('-name', `${testPatterns[i]}*`);
    }
    findArgs.push(')');

    const result = execFileSync('find', findArgs, { encoding: 'utf-8', timeout: 3000 });
    return result.trim().length > 0;
  } catch {
    return false;
  }
}

function getProjectRoot(): string {
  try {
    return execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf-8' }).trim();
  } catch {
    return '.';
  }
}

function logBlock(filePath: string, fileName: string): void {
  try {
    const logPath = projectPath('.ai', 'traces', 'hook-errors.log');
    mkdirSync(dirname(logPath), { recursive: true });
    const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
    appendFileSync(logPath, `${timestamp}|tdd-gate|block|${filePath}|no test file found for ${fileName}\n`);
  } catch {
    // Best-effort
  }
}

if (!process.env['VITEST']) {
  const run = createRunner(evaluate);
  await run();
}
