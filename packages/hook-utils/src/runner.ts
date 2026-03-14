import type { HookEvaluateFn, HookResult } from './types.ts';
import { readStdin } from './stdin.ts';

/**
 * Process a HookResult: write output and set exit code.
 * Exported for direct testing — in production, use createRunner().
 */
export function handleResult(result: HookResult): void {
  switch (result.mode) {
    case 'block': {
      const blockPayload: Record<string, string> = {
        decision: 'block',
        reason: result.reason ?? 'Blocked by hook',
      };
      if (result.systemMessage) {
        blockPayload.systemMessage = result.systemMessage;
      }
      process.stdout.write(JSON.stringify(blockPayload));
      process.exitCode = 2;
      break;
    }

    case 'warn':
      if (result.message) {
        process.stderr.write(result.message + '\n');
      }
      process.exitCode = 0;
      break;

    case 'notify':
      process.stdout.write(
        JSON.stringify({
          decision: 'approve',
          reason: result.reason ?? 'Advisory',
          systemMessage: result.systemMessage ?? result.message ?? '',
        }),
      );
      process.exitCode = 0;
      break;

    case 'allow':
    default:
      process.exitCode = 0;
  }
}

/**
 * Creates a hook runner that wires stdin -> evaluate -> stdout/stderr.
 * Handles exit codes based on HookResult mode:
 * - allow: exit 0, no output
 * - block: exit 2, JSON {"decision":"block","reason":"..."} to stdout
 * - warn:  exit 0, message to stderr
 */
export function createRunner(evaluate: HookEvaluateFn): () => Promise<void> {
  return async () => {
    try {
      const input = await readStdin();
      const result = await evaluate(input);
      handleResult(result);
    } catch {
      // Hooks must never crash — fail open
      process.exitCode = 0;
    }
    // Force exit — Node.js may keep event loop alive with stdin listeners
    process.exit();
  };
}
