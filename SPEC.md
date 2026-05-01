# SPEC: Production-Grade Time Awareness In Minimaxing

## Problem Statement

Make minmaxing estimate elapsed effort in agent-native wall-clock terms before
planning is frozen, instead of defaulting to vague human-calendar estimates.
The harness should force planning-time awareness across workflow, autoplan,
parallel execution, sprint execution, introspection, docs, and smoke tests.

## Codebase Anchors

- `CLAUDE.md` and `AGENTS.md` are the top-level awareness surfaces for Claude
  Code and Codex project instructions.
- `.claude/rules/estimation.rules.md` will be the authoritative reusable rule
  contract for agent-native estimates.
- `.claude/skills/workflow/SKILL.md` owns the end-to-end planning gate and
  workflow artifact sections.
- `.claude/skills/autoplan/SKILL.md` owns generated `SPEC.md` structure.
- `.claude/skills/parallel/SKILL.md` and `.claude/skills/sprint/SKILL.md`
  own packet-level duration, critical-path, and lane-bottleneck planning.
- `.claude/skills/introspect/SKILL.md` owns the hard-gate self-audit that must
  reject human-only or linearly scaled estimates.
- `scripts/parallel-capacity.sh --json` is the existing capacity evidence
  source for local hardware, Codex `max_threads`, and substrate ceilings.
- `scripts/test-harness.sh` and smoke scripts are the durable regression gates.

## Success Criteria

- [ ] Add `.claude/rules/estimation.rules.md` with the required estimate
      vocabulary: `agent_wall_clock`, `agent_hours`, `human_touch_time`,
      `calendar_blockers`, critical path, confidence, and capacity evidence.
- [ ] Update `CLAUDE.md` and `AGENTS.md` with top-level Planning Time Awareness
      requiring agent-native estimates before plan or `SPEC.md` freeze.
- [ ] Update `/workflow` so workflow artifacts require `## Agent-Native
      Estimate` after `## Plan` and before `## SPEC Decision`, and closeout
      blocks non-trivial workflows that have no estimate or only human time.
- [ ] Update `/autoplan` so generated `SPEC.md` includes `## Agent-Native
      Estimate` and derives it from the task DAG, effective lanes, barriers,
      ownership, and verification gates.
- [ ] Update `/parallel` and `/sprint` so every packet includes estimated
      duration and confidence, and project elapsed time is calculated from the
      longest dependency path instead of summed packet effort.
- [ ] Update `/introspect` with an estimation risk lane that returns
      `FIX_REQUIRED` for human-time defaulting, linear scaling, hidden blockers,
      missing verification time, or missing confidence labels.
- [ ] Add `scripts/estimate-history.sh` to summarize estimate-vs-actual data
      from `.taste/workflow-runs/` without inventing calibration numbers.
- [ ] Add `scripts/estimate-smoke.sh`, wire it into `scripts/test-harness.sh`,
      and keep the skill count stable at 22.
- [ ] Verification passes:
      `bash -n scripts/estimate-history.sh`,
      `bash -n scripts/estimate-smoke.sh`,
      `bash scripts/estimate-smoke.sh`,
      `bash scripts/parallel-capacity.sh --json`,
      `bash scripts/parallel-smoke.sh`,
      `bash scripts/test-harness.sh`, and `git diff --check`.

## Scope

### In Scope

- Harness-level planning-time awareness, not an optional direct helper skill.
- New estimation rules file and targeted skill/doc/test integration.
- Static smoke checks that reject human-only estimates and linear scaling.
- Lightweight calibration history script over existing workflow artifacts.
- Active spec and workflow artifact updates for this implementation.

### Out of Scope

- A scheduler daemon, queue runner, or autonomous timing service.
- A new `/estimate` skill in this first version.
- Claiming perfect model-internal clock awareness.
- Inventing historical calibration data before real runs record it.
- Changing AgentFactory runtime capacity semantics beyond referencing the
  shared estimation contract where relevant.

## Surgical Diff Discipline

- Smallest sufficient implementation: add one rules file, two scripts, and
  targeted contract references in existing docs, skills, and harness tests.
- No speculative abstractions: no scheduler, no new skill, no database schema,
  no daemon.
- No drive-by refactors: leave unrelated harness behavior and skill counts
  unchanged.
- Changed-line trace: every meaningful diff maps to a success criterion in
  this SPEC or to smoke-test coverage needed for the new planning gate.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local
- Capacity evidence: `scripts/parallel-capacity.sh --json` reported
  workstation, 16 cores, 32GB RAM, Codex `max_threads` 10, recommended ceiling
  10, default substrate `subagents`.
- Effective lanes: 1 of ceiling 10 for implementation because the patch is a
  coupled harness-contract edit with many shared docs and tests.
- Critical path: audit current contracts -> write active SPEC and workflow
  artifact -> update docs/skills/rules -> add scripts/tests -> verify smoke
  suite -> closeout archive.
- Agent wall-clock: optimistic 2 hours / likely 4 hours / pessimistic 7 hours.
- Agent-hours: 2-7 total active agent-hours.
- Human touch time: 10-30 minutes for reviewing the changed contracts and
  deciding whether to commit.
- Calendar blockers: full runtime Claude integration smoke is optional and
  depends on authenticated Claude settings; no external deployment blocker.
- Confidence: medium because static harness checks are predictable, while full
  runtime behavior depends on the LLM following the newly written contracts.
- Human-equivalent baseline: 1-2 engineer-days, secondary comparison only.

## Implementation Plan

### Phase 1: Estimation Contract Foundation

- [ ] Add `.claude/rules/estimation.rules.md` with required fields, forbidden
      estimate patterns, stable estimate block, calibration expectations, and
      critical-path math.
- [ ] Add top-level Planning Time Awareness to `CLAUDE.md`, `AGENTS.md`, and
      `README.md`.

### Phase 2: Planning And Execution Skill Integration

- [ ] Update `/workflow` artifact order, pre-spec gate, spec template,
      pre-closeout gate, actual timing closeout fields, and final output.
- [ ] Update `/autoplan` generated `SPEC.md` template and output summary.
- [ ] Update `/parallel` packet DAG, packet contract, bottleneck handling, and
      closeout.
- [ ] Update `/sprint` plan/distribution/quality gates for packet estimates.
- [ ] Update `/introspect` with estimation risk checks and output lane.

### Phase 3: Calibration And Regression Tests

- [ ] Add `scripts/estimate-history.sh` for lightweight historical summaries.
- [ ] Add `scripts/estimate-smoke.sh` with static assertions and negative
      estimate fixtures.
- [ ] Wire `estimate-smoke.sh` and the new scripts/rule into
      `scripts/test-harness.sh`.

### Phase 4: Verification And Archive

- [ ] Run syntax checks, smoke tests, full harness, and diff hygiene.
- [ ] Archive this active SPEC on verified closeout with the verified outcome.

## Verification

- `estimation.rules.md` contains the required vocabulary and references
  `scripts/parallel-capacity.sh --json`.
- `CLAUDE.md`, `AGENTS.md`, `/workflow`, `/autoplan`, `/parallel`, and
  `/introspect` all mention `Agent-Native Estimate`.
- `/sprint` includes packet duration and confidence requirements.
- `estimate-smoke.sh` rejects a human-equivalent-only estimate.
- `estimate-smoke.sh` rejects linear scaling language such as "10 agents means
  10x faster."
- `estimate-history.sh` runs without inventing calibration data.
- Existing parallel capacity and parallel smoke tests still pass.
- Full harness passes with the 22-skill expectation unchanged.

## Rollback Plan

1. Remove `.claude/rules/estimation.rules.md`.
2. Remove `scripts/estimate-history.sh` and `scripts/estimate-smoke.sh`.
3. Revert targeted `Agent-Native Estimate` changes in top-level docs, skills,
   rules, and `scripts/test-harness.sh`.
4. Restore the previous active spec from `.taste/specs/` if this work is
   abandoned before verified closeout.
