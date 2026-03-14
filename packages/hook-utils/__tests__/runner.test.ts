import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { handleResult } from '../src/runner.ts';

describe('handleResult', () => {
  let stdoutWrite: ReturnType<typeof vi.fn>;
  let stderrWrite: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    process.exitCode = undefined;
    stdoutWrite = vi.fn().mockReturnValue(true);
    stderrWrite = vi.fn().mockReturnValue(true);
    vi.spyOn(process.stdout, 'write').mockImplementation(stdoutWrite);
    vi.spyOn(process.stderr, 'write').mockImplementation(stderrWrite);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    process.exitCode = undefined;
  });

  it('allow mode sets exitCode 0 with no output', () => {
    handleResult({ mode: 'allow' });
    expect(process.exitCode).toBe(0);
    expect(stdoutWrite).not.toHaveBeenCalled();
    expect(stderrWrite).not.toHaveBeenCalled();
  });

  it('block mode sets exitCode 2 with JSON to stdout', () => {
    handleResult({ mode: 'block', reason: 'Push to main blocked' });
    expect(process.exitCode).toBe(2);
    expect(stdoutWrite).toHaveBeenCalledWith(
      JSON.stringify({ decision: 'block', reason: 'Push to main blocked' }),
    );
  });

  it('warn mode sets exitCode 0 with message to stderr', () => {
    handleResult({ mode: 'warn', message: 'Pencil swarm not configured' });
    expect(process.exitCode).toBe(0);
    expect(stderrWrite).toHaveBeenCalledWith('Pencil swarm not configured\n');
    expect(stdoutWrite).not.toHaveBeenCalled();
  });

  it('block mode with no reason uses default', () => {
    handleResult({ mode: 'block' });
    expect(stdoutWrite).toHaveBeenCalledWith(
      JSON.stringify({ decision: 'block', reason: 'Blocked by hook' }),
    );
  });

  it('warn mode with no message writes nothing to stderr', () => {
    handleResult({ mode: 'warn' });
    expect(process.exitCode).toBe(0);
    expect(stderrWrite).not.toHaveBeenCalled();
  });

  it('notify mode sets exitCode 0 with systemMessage JSON to stdout', () => {
    handleResult({ mode: 'notify', systemMessage: 'Check your docs' });
    expect(process.exitCode).toBe(0);
    expect(stdoutWrite).toHaveBeenCalledWith(
      JSON.stringify({ decision: 'approve', reason: 'Advisory', systemMessage: 'Check your docs' }),
    );
    expect(stderrWrite).not.toHaveBeenCalled();
  });

  it('notify mode with custom reason', () => {
    handleResult({ mode: 'notify', reason: 'Doc drift', systemMessage: 'Update docs' });
    expect(stdoutWrite).toHaveBeenCalledWith(
      JSON.stringify({ decision: 'approve', reason: 'Doc drift', systemMessage: 'Update docs' }),
    );
  });

  it('block mode includes systemMessage when provided', () => {
    handleResult({ mode: 'block', reason: 'Continue loop', systemMessage: 'Autopilot iteration 5' });
    expect(process.exitCode).toBe(2);
    const output = JSON.parse(stdoutWrite.mock.calls[0][0] as string) as Record<string, string>;
    expect(output.decision).toBe('block');
    expect(output.reason).toBe('Continue loop');
    expect(output.systemMessage).toBe('Autopilot iteration 5');
  });

  it('block mode omits systemMessage when not provided', () => {
    handleResult({ mode: 'block', reason: 'Blocked' });
    const output = JSON.parse(stdoutWrite.mock.calls[0][0] as string) as Record<string, string>;
    expect(output.systemMessage).toBeUndefined();
  });
});
