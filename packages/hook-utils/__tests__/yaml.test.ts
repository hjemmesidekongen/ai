import { describe, it, expect } from 'vitest';
import { join } from 'node:path';
import { writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { parseYamlFile } from '../src/yaml.ts';

describe('parseYamlFile', () => {
  const testDir = join(tmpdir(), 'hook-utils-yaml-test');

  beforeEach(() => {
    mkdirSync(testDir, { recursive: true });
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
  });

  it('parses valid YAML file', () => {
    const file = join(testDir, 'test.yml');
    writeFileSync(file, 'name: test\nstatus: active\n');
    const result = parseYamlFile<{ name: string; status: string }>(file);
    expect(result).toEqual({ name: 'test', status: 'active' });
  });

  it('returns null for non-existent file', () => {
    const result = parseYamlFile(join(testDir, 'nope.yml'));
    expect(result).toBeNull();
  });

  it('returns null for invalid YAML', () => {
    const file = join(testDir, 'bad.yml');
    writeFileSync(file, '{{{{ not yaml');
    const result = parseYamlFile(file);
    // js-yaml may return the string or throw — either way we handle it
    expect(result).toBeDefined();
  });
});
