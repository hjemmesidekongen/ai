# Design Loader — Process Reference

## Status Report Format

```
Design: {name}
Location: .ai/design/{name}/

Artifacts:
  [x] tokens.yml — 3 color palettes, 3 font families, 12 spacing steps
  [x] identity.yml — design rationale documented
  [ ] tokens/tailwind.json — run /segl:tokens to generate
  [ ] tokens/variables.css — run /segl:tokens to generate
  [ ] tokens/tokens.dtcg.json — run /segl:tokens to generate
  [ ] tokens/contrast-matrix.md — run /segl:tokens to generate

Next step: /segl:tokens
```

## Multi-Design Comparison Output

```
Comparing: design-a vs design-b

| Aspect          | design-a         | design-b         | Divergence |
|-----------------|------------------|------------------|------------|
| Color palettes  | 3 (pri/sec/acc)  | 2 (pri/acc)      | Missing secondary |
| Shared colors   | —                | 2 hex overlap    | #1A1A1A, #FFFFFF |
| Typography      | Inter + Mono     | Inter + Serif    | Body differs |
| Spacing base    | 4px              | 8px              | Different base |

Warning: consuming both designs downstream will produce inconsistent spacing.
```

## Context Resolution

1. Check `.ai/design/` for available design directories
2. If {name} specified, load that design. Otherwise list all available.
3. If no designs exist, report and suggest running /segl:identity

## Error Handling

- **Missing permissions**: report which files are unreadable and suggest `chmod` fix
- **Corrupt YAML**: use safe YAML parse; on failure report file path + error message
- **Schema version**: compare `version:` field in tokens.yml against token-schema.yml;
  warn if mismatch but still load what's parseable
- **Empty directory**: treat as "no design" — suggest /segl:identity
