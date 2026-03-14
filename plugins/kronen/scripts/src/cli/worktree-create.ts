import { createWorktree } from '../utils/worktree-create.ts';

createWorktree(process.argv[2] ?? '', process.argv[3] ?? '');
