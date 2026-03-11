# eslint-config — Process Reference

Full reference for flat config structure, migration, TypeScript setup, custom rules, plugins, shared configs, overrides, ignores, Prettier integration, performance, CI setup, and anti-patterns.

---

## Flat Config Structure (eslint.config.js)

```js
// eslint.config.js
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";
import globals from "globals";

export default [
  // 1. Base JS recommended rules
  js.configs.recommended,

  // 2. TypeScript — scoped to TS files only
  ...tseslint.configs.recommended.map((config) => ({
    ...config,
    files: ["**/*.ts", "**/*.tsx"],
  })),

  // 3. Language options (globals, ecmaVersion)
  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
  },

  // 4. Project-wide rule overrides
  {
    rules: {
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "no-console": "warn",
      eqeqeq: ["error", "always", { null: "ignore" }],
    },
  },

  // 5. Prettier last — disables formatting rules
  prettier,
];
```

Config objects are merged in array order. Later objects win on rule conflicts. There is no cascading directory lookup — one file controls everything.

---

## Migration from Legacy (.eslintrc → Flat)

### Automated migration
```bash
npx @eslint/migrate-config .eslintrc.js
# or for JSON
npx @eslint/migrate-config .eslintrc.json
```

The tool handles most conversions but produces verbose output. Review and simplify after running.

### Manual mapping

| Legacy | Flat config |
|--------|-------------|
| `extends: ["plugin:x/recommended"]` | `...pluginX.configs.recommended` (spread) |
| `env: { browser: true }` | `languageOptions: { globals: globals.browser }` |
| `parser: "@typescript-eslint/parser"` | `languageOptions: { parser: tsParser }` |
| `parserOptions: { project: true }` | `languageOptions: { parserOptions: { project: true } }` |
| `plugins: ["react"]` | `plugins: { react: reactPlugin }` (object, not array) |
| `ignorePatterns: ["dist/"]` | Top-level `ignores: ["dist/"]` config object |
| `overrides: [{ files, rules }]` | Separate config object with `files` glob |

### Compatibility shim (ESLint 8 plugins in ESLint 9)
```js
import { FlatCompat } from "@eslint/eslintrc";
const compat = new FlatCompat();

export default [
  ...compat.extends("plugin:legacy-plugin/recommended"),
];
```

Use `FlatCompat` only for plugins that haven't shipped flat config support. Check the plugin's changelog before reaching for it.

---

## TypeScript-ESLint Setup

### Basic (no type-aware rules)
```js
import tseslint from "typescript-eslint";

export default tseslint.config(
  tseslint.configs.recommended,
);
```

### Type-aware rules (slower, but catches more)
```js
export default tseslint.config(
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
);
```

Type-aware rules require a `tsconfig.json` and run the TypeScript compiler. They add 2–10s to lint time on large projects. Enable selectively if that's a concern.

### Key TypeScript rules

| Rule | Default | Notes |
|------|---------|-------|
| `@typescript-eslint/no-explicit-any` | warn | Don't set to error — some seams need it |
| `@typescript-eslint/no-floating-promises` | error | Type-aware; catches unawaited async calls |
| `@typescript-eslint/no-misused-promises` | error | Type-aware; prevents passing async where sync is expected |
| `@typescript-eslint/consistent-type-imports` | warn | Enforces `import type` for type-only imports |
| `@typescript-eslint/no-unnecessary-type-assertion` | warn | Type-aware; removes redundant `as` casts |

---

## Custom Rule Creation

Custom rules are functions that receive a `RuleContext`. ESLint exposes `context.report()` to flag problems.

```js
// rules/no-hardcoded-colors.js
export default {
  meta: {
    type: "suggestion",
    docs: { description: "Disallow hardcoded hex colors" },
    fixable: "code",
    schema: [],
  },
  create(context) {
    return {
      Literal(node) {
        if (typeof node.value === "string" && /^#[0-9a-fA-F]{3,6}$/.test(node.value)) {
          context.report({
            node,
            message: "Use a design token instead of a hardcoded color.",
          });
        }
      },
    };
  },
};
```

Register in flat config:
```js
import noHardcodedColors from "./rules/no-hardcoded-colors.js";

export default [
  {
    plugins: { local: { rules: { "no-hardcoded-colors": noHardcodedColors } } },
    rules: { "local/no-hardcoded-colors": "error" },
  },
];
```

Use `RuleTester` from `eslint` to unit test custom rules before wiring them in.

---

## Plugin Setup

Plugins export rules, processors, and optionally pre-built configs. In flat config, plugins are named objects — the name you give them becomes the rule prefix.

```js
import reactPlugin from "eslint-plugin-react";
import hooksPlugin from "eslint-plugin-react-hooks";

export default [
  {
    plugins: {
      react: reactPlugin,
      "react-hooks": hooksPlugin,
    },
    rules: {
      "react/prop-types": "off", // Using TypeScript
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "warn",
    },
  },
];
```

Common plugins:
- `eslint-plugin-react` + `eslint-plugin-react-hooks` — React rules
- `eslint-plugin-jsx-a11y` — Accessibility
- `eslint-plugin-import` — Import ordering and resolution
- `eslint-plugin-unicorn` — Opinionated modern JS patterns
- `eslint-plugin-sonarjs` — Bug detection patterns

---

## Shared Configs

A shared config is an npm package that exports a flat config array. Teams can publish internal configs and consume them like any other import.

```js
// packages/eslint-config/index.js
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  prettier,
  { rules: { "no-console": "warn" } },
];
```

```js
// apps/web/eslint.config.js
import baseConfig from "@company/eslint-config";

export default [
  ...baseConfig,
  { rules: { "no-console": "off" } }, // app-specific override
];
```

In a monorepo, use a local `packages/eslint-config` workspace package. Avoids duplication, keeps overrides explicit.

---

## Overrides and File-Specific Configs

Target specific file patterns with a `files` property on any config object:

```js
export default [
  // Apply to all files
  { rules: { "no-console": "warn" } },

  // Test files — relax rules
  {
    files: ["**/*.test.ts", "**/*.spec.ts", "**/tests/**"],
    rules: {
      "no-console": "off",
      "@typescript-eslint/no-explicit-any": "off",
    },
  },

  // Scripts — allow CommonJS and console
  {
    files: ["scripts/**/*.js"],
    languageOptions: { sourceType: "commonjs" },
    rules: { "no-console": "off" },
  },

  // Config files — allow require()
  {
    files: ["*.config.js", "*.config.ts"],
    rules: { "import/no-extraneous-dependencies": "off" },
  },
];
```

---

## Ignores

```js
export default [
  // Global ignores — applies to all configs
  { ignores: ["dist/", "build/", ".next/", "coverage/", "**/*.min.js"] },

  // ... rest of config
];
```

A config object with only `ignores` and no other keys is a global ignore pattern. An `ignores` field on a config object with other keys scopes the ignore to that config only.

`.eslintignore` is not supported in flat config — move all ignores into `eslint.config.js`.

---

## Integration with Prettier

ESLint and Prettier should not fight over formatting. The correct setup:

1. `eslint-config-prettier` — disables all ESLint rules that conflict with Prettier formatting
2. Put it **last** in the config array so it overrides everything above
3. Do **not** use `eslint-plugin-prettier` — it runs Prettier as an ESLint rule, which is slow and produces worse error messages

```js
import prettier from "eslint-config-prettier";

export default [
  // ... all other configs
  prettier, // must be last
];
```

Run Prettier separately (pre-commit hook, editor on-save, or CI check). ESLint handles logic; Prettier handles formatting.

---

## Performance

### Cache
```bash
eslint --cache --cache-location .eslintcache .
```

Add `.eslintcache` to `.gitignore`. Cache persists between runs and skips unchanged files. On large projects this reduces lint time by 60–80%.

### Max warnings
```bash
eslint --max-warnings 0 .
```

Exits non-zero if any warnings exist. Use in CI to prevent warning accumulation. Without this, `warn` rules are cosmetic.

### Lint only changed files (CI optimization)
```bash
# In CI, lint only files changed in the PR
git diff --name-only HEAD~1 HEAD | grep -E '\.(ts|tsx|js|jsx)$' | xargs eslint
```

### Disable type-aware rules for non-TS files
Type-aware rules require TypeScript compilation. Scoping them to `.ts`/`.tsx` avoids running the compiler on JS files.

---

## CI Integration

```yaml
# .github/workflows/lint.yml
- name: Lint
  run: npx eslint --cache --max-warnings 0 .
```

Key CI behaviors:
- Always use `--max-warnings 0` — treat warnings as errors
- Use `--cache` with a cached `.eslintcache` directory between runs
- Do not run `--fix` in CI — autofix changes files, which creates unexpected commit noise

```yaml
# Cache ESLint cache between CI runs
- uses: actions/cache@v4
  with:
    path: .eslintcache
    key: eslint-${{ hashFiles('eslint.config.js', 'package-lock.json') }}
```

---

## Common Anti-Patterns

### Conflicting rules from multiple configs
**Problem**: Two plugins enable rules that contradict each other (e.g., `import/order` and `simple-import-sort` both manage import ordering).
**Fix**: Pick one. Disable the other explicitly. Audit rule overlap when adding plugins.

### Disabling too much
**Problem**: `/* eslint-disable */` blocks accumulate. Rules are silenced without explanation.
**Fix**: Require a comment with every disable: `/* eslint-disable rule-name -- reason */`. Consider using a lint rule that enforces disable comments have descriptions (`eslint-comments/require-description`).

### Running autofix in CI
**Problem**: `eslint --fix` modifies files in CI. This either fails the pipeline (dirty working tree check) or silently changes committed code.
**Fix**: Never use `--fix` in CI. Use it in pre-commit hooks (via `lint-staged`) or editor integrations only.

### Applying TypeScript parser to all files
**Problem**: `languageOptions: { parser: tsParser }` set globally causes parse errors on `.js`, `.json`, and config files.
**Fix**: Scope typescript-eslint to `files: ["**/*.ts", "**/*.tsx"]`.

### Ignoring the `ignores` ordering requirement
**Problem**: `ignores` inside a config object with rules only ignores for that config, not globally.
**Fix**: Put global ignores in a standalone config object: `{ ignores: ["dist/"] }` with nothing else.

### No rule severity discipline
**Problem**: All rules are either `error` or `off`. `warn` is never used, or is used but `--max-warnings 0` is not set, making warnings meaningless.
**Fix**: Use `warn` for things you want to migrate away from but can't fix immediately. Always pair with `--max-warnings 0` in CI so the count stays at zero.
