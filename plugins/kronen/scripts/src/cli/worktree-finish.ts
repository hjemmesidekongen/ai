import { finishWorktree } from '../utils/worktree-finish.ts';

finishWorktree(process.argv[2] ?? '', process.argv[3] ?? '');
