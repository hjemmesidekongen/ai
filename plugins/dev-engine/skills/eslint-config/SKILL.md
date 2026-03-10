---
name: eslint-config
description: >
  ESLint flat config, custom rules, plugin setup, overrides, and migration
  from legacy .eslintrc format. Covers rule selection, TypeScript integration,
  Prettier compatibility, and CI performance.
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "eslint"
  - "eslint config"
  - "eslint flat config"
  - "linting rules"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "flat_config_not_legacy"
      verify: "Config uses eslint.config.js (flat config), not .eslintrc or eslintConfig in package.json"
      fail_action: "Migrate to flat config — legacy format is deprecated as of ESLint 9"
    - name: "no_conflicting_rules"
      verify: "No rule is set to both error and off in overlapping config objects for the same file pattern"
      fail_action: "Audit config merge order — later objects win; consolidate or use file-specific overrides"
    - name: "prettier_compat"
      verify: "If Prettier is in use, eslint-config-prettier is last in the config array to disable formatting rules"
      fail_action: "Add eslint-config-prettier as the final spread to prevent rule conflicts with Prettier"
    - name: "typescript_parser_scoped"
      verify: "typescript-eslint parser and type-aware rules are scoped to .ts/.tsx files only"
      fail_action: "Wrap typescript-eslint config in a files glob — applying it to .js files causes parse errors"
  on_fail: "ESLint config has structural problems — fix before committing"
  on_pass: "ESLint config is structurally sound"
_source:
  origin: "dev-engine"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
---

# eslint-config

ESLint 9 made flat config the default. Every new project should start with `eslint.config.js`. Legacy `.eslintrc` is deprecated and will be removed.

## Flat Config Overview

`eslint.config.js` exports an array of config objects. Each object applies to files matched by its `files` glob. Objects merge in order — later entries override earlier ones for the same rule.

```js
import js from "@eslint/js";
import globals from "globals";

export default [
  js.configs.recommended,
  { languageOptions: { globals: globals.browser } },
  { rules: { "no-unused-vars": "warn" } },
];
```

No more `extends` string references — import config objects directly. No more `env` — use `languageOptions.globals`.

## Migration from .eslintrc

Key differences: `extends` → spread config objects, `env` → `languageOptions.globals`, `parser` → `languageOptions.parser`, `parserOptions` → `languageOptions.parserOptions`, `plugins` → object map (not array), `ignorePatterns` → top-level `ignores` array.

Run `npx @eslint/migrate-config .eslintrc.js` for automated migration. Expect manual cleanup for complex plugin setups.

## When to Customize vs Use Presets

Start with a preset (`@eslint/js`, `typescript-eslint`, `eslint-config-prettier`). Customize only when a preset rule conflicts with team conventions or creates false positives in your stack. Disabling rules is a last resort — prefer configuring them.

## Key Rules to Know

- `no-unused-vars` — set to `["error", { argsIgnorePattern: "^_" }]` to allow intentional ignores
- `no-console` — `warn` in app code, disabled in scripts and CLI tools
- `eqeqeq` — always `error`; `== null` checks are the only safe exception
- `@typescript-eslint/no-explicit-any` — `warn`, not `error`; some integration seams need it

See `references/process.md` for flat config structure, TypeScript setup, custom rule creation, plugin setup, shared configs, file-specific overrides, ignores, Prettier integration, performance, CI setup, and anti-patterns.
