---
name: agency:trace
description: "Toggle and inspect structured trace capture for agency skill runs"
argument-hint: "on|off|list|show [file]"
---

# /agency:trace

Toggle trace capture and inspect trace files for the active project.

## Usage

```
/agency:trace on              # Enable full trace mode
/agency:trace on decision-only # Enable decision-only mode
/agency:trace off             # Disable tracing
/agency:trace list            # List trace files for active project
/agency:trace show [file]     # Show human-readable trace summary
```

## Execution Steps

### Step 1: Parse Subcommand

```
args = parse arguments
subcommand = args[0]   # on | off | list | show

if subcommand not in [on, off, list, show]:
  "Usage: /agency:trace on|off|list|show [file]"
  exit
```

### Step 2: Load Active Project

```
Read .ai/agency.yml → active project name
if no agency.yml:
  "No agency registry found. Run /agency:init first."
  exit

state_file = .ai/projects/{project}/state.yml
if not exists:
  "No state file for project '{project}'. Run /agency:init first."
  exit

state = read_yaml(state_file)
```

### Step 3: Execute Subcommand

#### Subcommand: `on`

```
mode = args[1] or "full"       # default to full
if mode not in [full, decision-only]:
  "Invalid mode. Use 'full' or 'decision-only'."
  exit

traces_dir = .ai/projects/{project}/traces/
mkdir -p traces_dir

Update state.yml:
  trace:
    enabled: true
    mode: {mode}
    traces_dir: "{traces_dir}"

"Trace enabled (mode: {mode}). Traces will be written to {traces_dir}"
```

#### Subcommand: `off`

```
Update state.yml:
  trace:
    enabled: false

"Trace disabled for project '{project}'."
```

#### Subcommand: `list`

```
traces_dir = state.trace.traces_dir or .ai/projects/{project}/traces/
if traces_dir does not exist or is empty:
  "No trace files found for project '{project}'."
  exit

List all .yml files in traces_dir, sorted by modification time (newest first).

Display table:
| # | Skill | Timestamp | Mode | Steps | Avg Uncertainty |
|---|-------|-----------|------|-------|-----------------|
| 1 | feature-decomposer | 2026-03-04T14:23:01Z | full | 6 | 0.15 |
| 2 | brand-loader | 2026-03-04T14:10:00Z | full | 4 | 0.05 |
```

#### Subcommand: `show`

```
file = args[1]
if not file:
  "Usage: /agency:trace show <filename>"
  "Run /agency:trace list to see available files."
  exit

trace_path = traces_dir / file
if not exists: try traces_dir / file + ".yml"
if still not exists:
  "Trace file not found: {file}"
  exit

trace = read_yaml(trace_path)

Display:
## Trace: {trace._meta.skill} ({trace._meta.trace_mode})
Project: {trace._meta.project} | Duration: {trace._meta.duration_seconds}s | Tokens: ~{trace._meta.token_estimate}

### Steps
For each step:
  **{step.step}** — uncertainty: {step.uncertainty}
  Decision: {step.decision}
  {if flags: "⚠ Flags: {flags}"}
  {if reasoning: "Reasoning: {step.reasoning}"}

### Uncertainty Heatmap
Render each step as: [name] [bar visualization of uncertainty]
  Step 1: ░░ (0.1)
  Step 2: ░░░░░░ (0.6)    ← highest uncertainty
  Step 3: ░ (0.05)

### Checkpoint
Status: {checkpoint_result.status} ({checks_passed}/{checks_run} passed)
{if failure_details: list each failure}

### Quality Summary
Average uncertainty: {quality_summary.avg_uncertainty}
Lowest confidence: {quality_summary.lowest_confidence_step}
Flags raised: {quality_summary.flags_raised}
Recommendation: {quality_summary.recommendation}

### Token Budget
| Step | Tokens |
|------|--------|
For each step: | {step.step} | ~{step.token_estimate_step} |
| **Total** | **~{trace._meta.token_estimate}** |
```
