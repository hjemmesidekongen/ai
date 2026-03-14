import { assembleContext } from '../utils/assemble-context.ts';

const source = process.argv[2] ?? 'unknown';
assembleContext(source);
