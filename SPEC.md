# SPEC: Parallel-Aware Metacognition Mode

## Problem Statement

minmaxing already has strong `/workflow`, `/deepresearch`, `/parallel`, and
`/introspect` contracts, but it does not have a first-class metacognitive
control plane that routes task depth, accounts for parallel capacity, and rejects
shallow self-reflection as a harness-level quality gate.

## Codebase Anchors

- `docs/metacognition-harness-moat-research-2026-05-03.md` contains the
  research-backed rationale and first implementation slice.
- `.claude/skills/workflow/SKILL.md` owns the full lifecycle and workflow
  artifact shape.
- `.claude/skills/introspect/SKILL.md` owns the hard-gate self-audit protocol.
- `scripts/harness-scorecard.sh`, `scripts/harness-eval.sh`, and
  `scripts/test-harness.sh` are the existing static governance patterns.
- `scripts/parallel-capacity.sh --json` is the local capacity source; its
  current output reports `codex_max_threads=10`, `recommended_ceiling=10`,
  `hardware_class=workstation`, and `agent_teams_available=false`.

## Success Criteria

- [x] Add a public `/metacognition` skill that classifies tasks, computes an
      effective parallel budget, records evidence requirements, and routes to
      existing harness commands without replacing `/workflow` or `/introspect`.
- [x] Add metacognition rules that forbid raw hidden chain-of-thought
      dependency, require evidence-grounded reflection, and treat
      `MAX_PARALLEL_AGENTS` as a ceiling rather than a quota.
- [x] Extend `/workflow` artifacts with a compact `## Metacognitive Route`
      section before `## Research Brief`.
- [x] Extend `/introspect` with second-order judgment checks for evidence,
      self-report overtrust, missed failure modes, confidence downgrades, and
      parallel misuse.
- [x] Add `scripts/metacognition-scorecard.sh --fixtures --json` with stable
      red-rule detection for missing route, missing parallel budget, linear
      parallel claims, unsupported reflection, unsupported confidence, raw CoT
      dependency, unverified self-report promotion, and unresolved blocker
      closeout.
- [x] Add harness eval metadata/golden coverage for the metacognition scorecard.
- [x] Register `/metacognition` and `metacognition-scorecard.sh` in docs,
      startup, release, and full harness checks; update expected skill counts
      from 24 to 25.

## Scope

### In Scope

- Static contract, skill, rule, fixture, scorecard, eval, docs, and harness
  wiring.
- Minimal updates to `/workflow` and `/introspect` contracts.
- Local no-secret verification only.

### Out of Scope

- Provider API changes.
- Model fine-tuning.
- Capturing or scoring raw hidden chain-of-thought.
- New runtime sidecar systems beyond fixtures used by the static scorecard.
- Changes to Hermes agent registry state unrelated to this task.

## Surgical Diff Discipline

- Smallest sufficient implementation: add one skill, one rule, one scorecard,
  fixtures/eval metadata, and the minimal docs/harness registration needed to
  enforce the contract.
- No speculative abstractions: do not create a new workflow engine or runtime
  database.
- No drive-by refactors: leave unrelated harness behavior and existing Hermes
  registry changes untouched.
- Changed-line trace: every meaningful edit must trace to one success criterion
  above or to static verification needed for this slice.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local serial implementation, parallel-aware design
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` on 2026-05-03
  reported `codex_max_threads=10`, `recommended_ceiling=10`,
  `hardware_class=workstation`, and `agent_teams_available=false`
- Effective lanes: 1 of ceiling 10 because the first slice is tightly coupled
  across shared harness contracts
- Critical path: archive old SPEC -> write active SPEC -> add skill/rule ->
  add scorecard/fixtures/eval metadata -> update workflow/introspect/docs/startup
  -> run static checks -> fix regressions
- Agent wall-clock: optimistic 90 minutes / likely 2.5 hours / pessimistic
  4 hours
- Agent-hours: 2-4 active agent-hours
- Human touch time: none expected during implementation
- Calendar blockers: none unless full release check exposes slow CI-like gates
- Confidence: medium-high because existing scorecard/eval patterns are already
  present; risk is broad registration drift across docs and test-harness counts

## Verification

- `bash -n scripts/*.sh`
- `bash scripts/metacognition-scorecard.sh --fixtures --json`
- `bash scripts/harness-eval.sh --json`
- `bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

Verified locally on 2026-05-03:

- `bash -n scripts/metacognition-scorecard.sh scripts/harness-eval.sh scripts/test-harness.sh scripts/release-check.sh scripts/start-session.sh`: pass
- `bash scripts/metacognition-scorecard.sh --fixtures --json`: pass, 3 green
  fixtures accepted, 8 red fixtures rejected, no missing rules
- `bash scripts/harness-eval.sh --json`: pass, 13 tasks, 10 gates, 0
  mismatches
- `bash scripts/visualize-smoke.sh`: pass after updating stale 24-skill
  assertions to 25
- `bash scripts/release-check.sh --static-only --skip-full-harness`: pass
- `bash scripts/test-harness.sh`: pass, 107 passed, 0 failed
- `bash scripts/release-check.sh --static-only`: pass, includes
  `HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`, 107 passed, 0 failed

## Rollback Plan

- Remove `.claude/skills/metacognition/`, `.claude/rules/metacognition.rules.md`,
  `scripts/metacognition-scorecard.sh`, `.taste/fixtures/metacognition/`, and
  the metacognition eval task/golden.
- Revert docs/startup/harness count changes from 25 back to 24.
- Remove the `## Metacognitive Route` workflow artifact requirement and the
  second-order checks from `/introspect`.
- Run `bash scripts/release-check.sh --static-only`.
