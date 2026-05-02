# SPEC: Visualize And VisualizeWorkflow Skills

## Problem Statement

Add a visualization capability that lets the harness prove it understands a
project's taste and intended product experience before implementation, without
slowing down or blocking normal autonomous `/workflow` execution.

The correction from the first plan is important: plain `/workflow` remains the
autonomous executor. Human visual approval belongs in an explicit
`/visualizeworkflow` route.

## Codebase Anchors

- `.claude/skills/` contains slash-command skill contracts.
- `.claude/skills/workflow/SKILL.md` is the autonomous end-to-end executor and
  must not gain a mandatory visual approval pause.
- `taste.md` and `taste.vision` are the repo's operating kernel and must be read
  before visualization.
- `scripts/test-harness.sh`, `scripts/start-session.sh`, `README.md`, and
  `CLAUDE.md` currently describe a 22-skill surface and must move to 24 skills.
- `.taste/*` is ignored except committed fixture folders, so
  `.taste/visualizations/` is the right generated-artifact location.

## Success Criteria

- [x] Add standalone `/visualize` skill.
- [x] Add approval-first `/visualizeworkflow` skill.
- [x] Add visualization rules for artifact modes, privacy boundaries, no fake
      image claims, and autonomous `/workflow` preservation.
- [x] Update `/workflow` so it can point users to `/visualizeworkflow` for
      explicit approval-first work without adding a mandatory visualization gate.
- [x] Update skill counts and skill lists from 22 to 24.
- [x] Add a static `visualize-smoke` gate and wire it into the full harness and
      release check.
- [x] Keep static checks no-secret and provider-independent.

## Scope

### In Scope

- Skill contracts, rules, docs, start-session, harness tests, and release gate.
- Ignored visualization run artifact contract under `.taste/visualizations/`.
- Static enforcement that `/workflow` remains autonomous.

### Out of Scope

- New image-generation API client or provider integration.
- Committing generated visualization artifacts.
- Requiring image-generation credentials for static tests.
- Making `/workflow` wait for visual approval by default.

## Surgical Diff Discipline

- Smallest sufficient implementation: add two skills, one rules file, one smoke
  script, and narrow docs/test wiring.
- No speculative abstractions: do not build a scheduler, visual dashboard,
  plugin installer, or image-generation wrapper.
- No drive-by refactors: keep unrelated runtime-hardening, memory, security, and
  parallel scripts untouched.
- Changed-line trace: every edit maps to one of the success criteria above.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local
- Capacity evidence: `scripts/parallel-capacity.sh --json` reported
  workstation, 16 cores, 32GB RAM, Codex `max_threads` 10, recommended ceiling
  10, default substrate `subagents`
- Effective lanes: 1 of ceiling 10 because this is one coherent harness surface
  edit with shared docs/test counts
- Critical path: spec -> skills/rules -> workflow autonomy note -> docs/counts
  -> smoke gate -> full harness/release verification
- Agent wall-clock: optimistic 90 minutes / likely 3 hours / pessimistic 5 hours
- Agent-hours: 3-6 active agent-hours
- Human touch time: 10-20 minutes to review whether `/visualizeworkflow` feels
  strict enough
- Calendar blockers: none for static local implementation
- Confidence: medium-high because the implementation is deterministic docs and
  shell gating, but skill wording must avoid overblocking `/workflow`
- Human-equivalent baseline: 1 engineer-day, secondary comparison only

## Implementation Plan

1. [x] Add `.claude/skills/visualize/SKILL.md`.
2. [x] Add `.claude/skills/visualizeworkflow/SKILL.md`.
3. [x] Add `.claude/rules/visualization.rules.md`.
4. [x] Update `.claude/skills/workflow/SKILL.md` with non-blocking routing rules.
5. [x] Update README, CLAUDE, AGENTS, and `scripts/start-session.sh` skill counts
   and lists.
6. [x] Add `scripts/visualize-smoke.sh`.
7. [x] Wire the smoke into `scripts/test-harness.sh` and
   `scripts/release-check.sh`.
8. [x] Verify with the target commands and close out.

## Verification

- `bash -n scripts/visualize-smoke.sh`
- `bash scripts/visualize-smoke.sh`
- `bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

Verified on 2026-05-02:

- `bash -n scripts/*.sh`: pass
- `bash -n scripts/visualize-smoke.sh`: pass
- `bash scripts/visualize-smoke.sh`: pass
- `bash scripts/test-harness.sh`: pass, 103 passed, 0 failed
- `bash scripts/release-check.sh --static-only`: pass, includes
  `scripts/visualize-smoke.sh`, full harness, and `git diff --check`

## Rollback Plan

- Remove `/visualize`, `/visualizeworkflow`, visualization rules, and
  `scripts/visualize-smoke.sh`.
- Restore skill counts and `/workflow` text to the previous 22-skill surface.
- Run `bash scripts/test-harness.sh` and `git diff --check`.
