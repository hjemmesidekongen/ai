# verification-gate — Process

## Proof Command Selection by Task Type

Choose the proof command that produces observable, unambiguous output.

### Shell scripts / hooks

```bash
# Syntax check
bash -n <script.sh> && echo "Syntax OK"

# Functional test (minimal input)
CLAUDE_PROJECT_DIR=. bash <script.sh> 2>&1

# Performance
time CLAUDE_PROJECT_DIR=. bash <script.sh>
```

Pass criteria: syntax OK, no error output, runtime within target.

### JSON / YAML files

```bash
# JSON
python3 -m json.tool <file.json> > /dev/null && echo "Valid"

# YAML (basic)
python3 -c "import yaml,sys; yaml.safe_load(open('$f'))" && echo "Valid"

# grep for required keys
grep -c 'required_key' <file.yml>
```

Pass criteria: parser exits 0, required keys present.

### Skill / command / agent files

```bash
# Required frontmatter keys present
grep -c '^name:' <SKILL.md>
grep -c '^description:' <SKILL.md>

# Line count within limit
wc -l <SKILL.md>   # ≤80 for SKILL.md

# References dir exists if overflow
ls <skill>/references/ 2>/dev/null
```

Pass criteria: all required sections present, line limits respected.

### Plan wave completion

```bash
# State updated
grep 'status: done' .ai/plans/<name>/state.yml

# Files exist
ls <expected output files>

# No errors logged
grep -c 'result: unresolved' .ai/plans/<name>/state.yml || echo 0
```

Pass criteria: wave status done, all output files exist, no unresolved errors.

### Plugin registration

```bash
# ecosystem.json contains the component
grep '"<component-name>"' .claude-plugin/ecosystem.json

# plugin.json valid
python3 -m json.tool .claude-plugin/plugin.json > /dev/null && echo "Valid"
```

Pass criteria: component appears in registry, JSON valid.

### Code / feature implementation

```bash
# Existing test suite
npm test / pytest / cargo test / go test ./...

# Targeted smoke test
node -e "require('./dist'); console.log('OK')"

# Lint / type check
tsc --noEmit / eslint src/
```

Pass criteria: tests pass, no type errors, no lint errors.

## Verdict Format

After running proof, state the verdict explicitly:

```
Proof: bash -n scripts/verification-gate-stop.sh
Output: (no output)
Exit: 0
Verdict: PASS — syntax valid
```

Or on failure:

```
Proof: python3 -m json.tool plugin.json
Output: Expecting ',' delimiter: line 52
Exit: 1
Verdict: FAIL — malformed JSON at line 52
```

Never omit the proof command or the actual output.

## Integration with plan-verifier

`plan-verifier` checks wave *outputs* (files exist, schema valid, ownership).
`verification-gate` checks that Claude *ran proof* before claiming done.

They are complementary:
- verification-gate: Did Claude verify before claiming?
- plan-verifier: Are the wave outputs structurally correct?

Both must pass before a wave can advance.

## Stop Hook Behavior

`verification-gate-stop.sh` fires at session end. It checks trace-light.log:
if the most recent operations in an active plan are only writes with no
subsequent Bash/Read/Grep verification step, it emits an advisory.

This is a reminder, not a block. The discipline is enforced by the protocol
above, not by the hook alone.

## Escalation

If verification fails after 3 attempts:
- Log to state.yml errors array with `result: unresolved`
- Surface the blocker to the user
- Do not retry the same approach
- Consider whether the task definition needs revision
