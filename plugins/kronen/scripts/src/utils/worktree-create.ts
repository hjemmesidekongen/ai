import { existsSync, readFileSync, appendFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const VALID_NAME_PATTERN = /^[a-zA-Z0-9._/-]+$/;

/**
 * Creates a git worktree at .worktrees/<name>/ on a new branch.
 * Ensures .worktrees/ is gitignored, detects project type, runs setup.
 */
export function createWorktree(name: string, branch: string): void {
  if (!name || !branch) {
    process.stderr.write('Usage: worktree-create <name> <branch-name>\n');
    process.exit(1);
  }

  if (!VALID_NAME_PATTERN.test(name) || !VALID_NAME_PATTERN.test(branch)) {
    process.stderr.write('Error: name and branch must match [a-zA-Z0-9._/-]+\n');
    process.exit(1);
  }

  const worktreeDir = `.worktrees/${name}`;

  // Step 1: Gitignore safety
  ensureGitignore();

  // Step 2: Create worktree
  if (existsSync(worktreeDir)) {
    process.stderr.write(`Error: ${worktreeDir} already exists.\n`);
    process.exit(1);
  }

  console.log(`Creating worktree '${name}' on branch '${branch}'...`);
  execFileSync('git', ['worktree', 'add', worktreeDir, '-b', branch], { stdio: 'inherit' });
  console.log(`Worktree created at ${worktreeDir}`);

  // Step 3: Setup detection
  runSetup(worktreeDir);

  // Step 4: Baseline verification
  try {
    const dirty = execFileSync('git', ['-C', worktreeDir, 'status', '--porcelain'], { encoding: 'utf-8' })
      .split('\n')
      .filter((l) => l.length > 0 && !l.startsWith('?'))
      .join('\n');

    if (dirty) {
      console.log('Warning: unexpected dirty files after setup:');
      console.log(dirty);
      console.log('Inspect before proceeding.');
    } else {
      console.log('Baseline clean.');
    }
  } catch { /* skip */ }

  console.log(`\nWorktree ready.`);
  console.log(`  Path:   ${worktreeDir}`);
  console.log(`  Branch: ${branch}`);
  console.log(`\nFinish with: node plugins/kronen/scripts/dist/worktree-finish.js ${name} merge|pr|keep|discard`);
}

function ensureGitignore(): void {
  if (existsSync('.gitignore')) {
    const content = readFileSync('.gitignore', 'utf-8');
    if (!content.includes('.worktrees')) {
      console.log('Adding .worktrees/ to .gitignore...');
      appendFileSync('.gitignore', '\n.worktrees/\n');
      execFileSync('git', ['add', '.gitignore']);
      execFileSync('git', ['commit', '-m', 'add .worktrees/ to gitignore']);
    }
  } else {
    writeFileSync('.gitignore', '.worktrees/\n');
    execFileSync('git', ['add', '.gitignore']);
    execFileSync('git', ['commit', '-m', 'add .gitignore with .worktrees/ pattern']);
  }
}

function runSetup(worktreeDir: string): void {
  const lockFiles: Array<[string, string, string[]]> = [
    ['yarn.lock', 'yarn', ['install', '--frozen-lockfile']],
    ['pnpm-lock.yaml', 'pnpm', ['install', '--frozen-lockfile']],
    ['package-lock.json', 'npm', ['install']],
    ['Gemfile', 'bundle', ['install', '--quiet']],
    ['requirements.txt', 'pip', ['install', '-r', 'requirements.txt', '-q']],
    ['go.mod', 'go', ['mod', 'download']],
  ];

  for (const [lockFile, cmd, args] of lockFiles) {
    if (existsSync(`${worktreeDir}/${lockFile}`)) {
      console.log(`Detected ${lockFile}. Running ${cmd} install...`);
      try {
        execFileSync(cmd, args, { cwd: worktreeDir, stdio: 'inherit' });
      } catch {
        console.log(`Warning: ${cmd} install had issues. Check manually.`);
      }
      return;
    }
  }

  if (existsSync(`${worktreeDir}/package.json`)) {
    console.log('Detected package.json. Running npm install...');
    try {
      execFileSync('npm', ['install'], { cwd: worktreeDir, stdio: 'inherit' });
    } catch { /* skip */ }
    return;
  }

  console.log('No setup file detected. Skipping setup.');
}
