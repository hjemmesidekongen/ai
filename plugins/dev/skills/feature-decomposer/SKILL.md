---
name: feature-decomposer
user-invocable: false
description: >
  Phase 1 of /dev:build — PM orchestrates Architect, Designer, and PO agents to
  break a feature into components with boundaries, visual specs, and validated scope.
  Use when decomposing features, running /dev:build phase 1, defining component
  boundaries, producing visual specs, or validating feature scope.
phase: 1
depends_on: [config-generator]
writes:
  - ".ai/dev/[project-name]/team-state.yml (decomposition section)"
reads:
  - "User's feature description (from /dev:build argument)"
  - ".ai/dev/[project-name]/dev-config.yml"
  - ".ai/dev/[project-name]/knowledge/*.yml (tag-filtered)"
  - "brand-reference.yml (optional, via brand-context-loader)"
model_tier: principal
interactive: true
checkpoint:
  type: data_validation
  required_checks:
    - name: "components_exist"
      verify: "At least 1 component in team-state.yml decomposition.components"
      fail_action: "Re-run Architect agent with simplified scope"
    - name: "component_fields_complete"
      verify: "Every component has non-empty: name, description, boundaries, type"
      fail_action: "Fill missing fields from Architect's analysis or ask user"
    - name: "files_affected_populated"
      verify: "Every component has at least 1 entry in files_affected"
      fail_action: "Derive files from component boundaries and project structure"
    - name: "po_validation_recorded"
      verify: "decomposition.po_validation.status is approved, revised, or rejected"
      fail_action: "Dispatch PO agent to validate scope"
    - name: "designer_specs_if_ui"
      verify: "If any component has type=frontend: at least 1 designer_specs entry"
      fail_action: "Dispatch Designer agent for frontend components"
  on_fail: "Fix issues and re-run checkpoint. Do not advance to Phase 2."
  on_pass: "Update team-state.yml status to planning, advance to Phase 2."
---

# Feature Decomposer

Phase 1 of /dev:build. Receives a feature description, orchestrates Architect (boundaries), Designer (visual specs), and PO (scope validation) agents, presenting each perspective to the user for feedback before finalizing.

## Context

| Aspect | Details |
|--------|---------|
| **Reads** | feature description, dev-config.yml, knowledge files, brand data (optional) |
| **Writes** | team-state.yml decomposition section (components, designer_specs, po_validation) |
| **Checkpoint** | data_validation: components exist, fields complete, files listed, PO status, designer specs for UI |
| **Dependencies** | config-generator (dev-config.yml must exist) |

## Agent Orchestration Summary

1. PM presents feature understanding to user for confirmation
2. Architect analyzes against existing architecture → component breakdown
3. User reviews Architect's proposal
4. Designer produces visual specs for frontend components (if any)
5. User reviews Designer's specs
6. PO validates scope completeness and appropriateness
7. User reviews PO assessment → final confirmation

## Findings Persistence

Write intermediate discoveries to `.ai/dev/[project-name]/findings.md`.
**2-Action Rule:** After every 2 agent dispatches or user interactions, save findings immediately.

## Error Logging — Log errors to state.yml errors array. Check errors before retrying.

## Execution — [references/process.md](references/process.md)
