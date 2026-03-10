/**
 * Syncs MDX docs from ../docs into content/docs for Fumadocs.
 * Copies only .mdx files and meta.json — the docs/ folder remains the single source of truth.
 */
import { cpSync, mkdirSync, rmSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SOURCE = resolve(__dirname, '../../docs');
const DEST = resolve(__dirname, '../content/docs');

// On Vercel with rootDirectory=site, ../docs isn't accessible.
// Fall back to committed content/docs/ if source doesn't exist.
if (!existsSync(SOURCE)) {
  if (existsSync(DEST)) {
    console.log('[sync-docs] Source not found, using committed content/docs');
  } else {
    console.error('[sync-docs] No source docs and no content/docs — build will fail');
    process.exit(1);
  }
} else {
  // Clean destination
  if (existsSync(DEST)) {
    rmSync(DEST, { recursive: true });
  }
  mkdirSync(DEST, { recursive: true });

  // Copy .mdx files and meta.json
  cpSync(SOURCE, DEST, {
    recursive: true,
    filter: (src) => {
      const name = src.split('/').pop();
      // Allow directories to be traversed
      if (!name.includes('.')) return true;
      // Only copy .mdx and meta.json
      return name.endsWith('.mdx') || name === 'meta.json';
    },
  });

  console.log('[sync-docs] Synced docs → content/docs');
}
