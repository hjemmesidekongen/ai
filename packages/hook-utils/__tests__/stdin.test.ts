import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { Readable } from 'node:stream';

describe('readStdin', () => {
  let originalStdin: typeof process.stdin;

  beforeEach(() => {
    originalStdin = process.stdin;
  });

  afterEach(() => {
    Object.defineProperty(process, 'stdin', { value: originalStdin, writable: true });
    vi.restoreAllMocks();
  });

  function mockStdin(data: string): void {
    const readable = Readable.from([data]);
    Object.defineProperty(process, 'stdin', { value: readable, writable: true });
  }

  it('parses valid JSON from stdin', async () => {
    mockStdin('{"tool_name":"Bash","tool_input":{"command":"ls"}}');
    // Re-import to get fresh module with mocked stdin
    const { readStdin } = await import('../src/stdin.ts');
    const result = await readStdin();
    expect(result.tool_name).toBe('Bash');
    expect(result.tool_input).toEqual({ command: 'ls' });
  });

  it('returns empty object for empty stdin', async () => {
    mockStdin('');
    const { readStdin } = await import('../src/stdin.ts');
    const result = await readStdin();
    expect(result).toEqual({});
  });

  it('returns empty object for invalid JSON', async () => {
    mockStdin('not json {{{');
    const { readStdin } = await import('../src/stdin.ts');
    const result = await readStdin();
    expect(result).toEqual({});
  });
});
