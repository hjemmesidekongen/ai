# Plugin Ecosystem Project

## What We're Building
Two Claude Code plugins that work together:
1. **task-planner** — Generic wave-based task planning with verification and QA
2. **brand-guideline** — Agency-grade brand guideline generator

## Architecture Rules
- task-planner is a dependency of brand-guideline (build planner first)
- All plugins follow Claude Code plugin structure: .claude-plugin/plugin.json, commands/, skills/, agents/
- Plugins produce dual outputs: human-readable docs + machine-readable YAML
- Every task must pass verification before being marked complete
- A dedicated QA agent reviews all completed work — implementing agents never self-grade
- Multi-agent runs use file-ownership to prevent write conflicts

## Project Structure
packages/
  task-planner/           # Generic planning plugin
  brand-guideline/        # Brand-specific plugin
shared/
  brand-context-loader/   # Shared skill used by all brand-consuming plugins

## Current Phase
Phase 1: Building task-planner plugin — starting with scaffold and plan schema

## Specs
Detailed specs are in /docs/ — read the relevant spec BEFORE implementing.
Do NOT try to build everything at once. Follow the phase plan.
