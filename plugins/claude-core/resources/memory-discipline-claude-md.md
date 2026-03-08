# Memory Discipline (CLAUDE.md addition)

The following block is intended to be appended to CLAUDE.md.
It summarizes the rules from `plugins/claude-core/resources/memory-rules.md`
in the compact format CLAUDE.md requires.

---

```
## Memory Discipline
- MEMORY.md: max 150 lines. Facts, preferences, pointers only. No narrative.
- CLAUDE.md: rules and behaviors. MEMORY.md: facts. decisions.yml: reasoning. roadmap.yml: ideas.
- Graduate entries: when a memory becomes a rule, skill, or code — delete it from MEMORY.md.
- Not everything said is an instruction. Wait for decisions; don't store thinking-out-loud.
- When in doubt, don't store. Over-storing creates noise that degrades every session.
- Pruning: delete entries that are stale (30+ days unreferenced), duplicated, or graduated.
- Never store temporary state, code, or implementation details in MEMORY.md.
- Full rules: plugins/claude-core/resources/memory-rules.md
```
