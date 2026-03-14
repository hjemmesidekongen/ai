import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { evaluate } from '../src/hooks/cache-clear.ts';

describe('cache-clear', () => {
  const testHome = join(tmpdir(), 'cache-clear-test');
  const cacheDir = join(testHome, '.claude', 'plugins', 'cache', 'hjemmesidekongen-ai');

  beforeEach(() => {
    mkdirSync(cacheDir, { recursive: true });
    process.env['HOME'] = testHome;
  });

  afterEach(() => {
    rmSync(testHome, { recursive: true, force: true });
    vi.restoreAllMocks();
  });

  it('returns allow mode', () => {
    const result = evaluate({});
    expect(result.mode).toBe('allow');
  });

  it('deletes the cache directory when it exists', () => {
    expect(existsSync(cacheDir)).toBe(true);
    evaluate({});
    expect(existsSync(cacheDir)).toBe(false);
  });

  it('does not throw when cache directory does not exist', () => {
    rmSync(testHome, { recursive: true, force: true });
    expect(() => evaluate({})).not.toThrow();
  });

  it('does not throw when HOME is not set', () => {
    delete process.env['HOME'];
    delete process.env['USERPROFILE'];
    expect(() => evaluate({})).not.toThrow();
  });
});
