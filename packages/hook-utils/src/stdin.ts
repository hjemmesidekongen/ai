import type { HookInput } from './types.ts';

/** Read all data from stdin and parse as JSON. Returns empty object on failure. */
export async function readStdin(): Promise<HookInput> {
  const chunks: string[] = [];

  return new Promise((resolve) => {
    process.stdin.setEncoding('utf-8');

    process.stdin.on('data', (chunk: string) => {
      chunks.push(chunk);
    });

    process.stdin.on('end', () => {
      const raw = chunks.join('').trim();
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw) as HookInput);
      } catch {
        resolve({});
      }
    });

    process.stdin.on('error', () => {
      resolve({});
    });

    // Handle piped input that's already closed
    if (process.stdin.readableEnded) {
      resolve({});
    }
  });
}
