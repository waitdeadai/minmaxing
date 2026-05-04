# SPEC: Hive Mind Skill And Hiveworkflow Mode

## Problem Statement

minmaxing has `/parallel` for hardware-aware packet execution and
`/metacognition` for route steering, but it does not yet have a first-class
contract for coordinated multi-agent cognition: roles, shared blackboard state,
dissent, synthesis, arbitration, and verified collective output.

The user wants a "hive mind" mode that can spawn parallel agents to coordinate
work, but the harness must prevent agent theater, linear scaling claims, shared
state corruption, and consensus without evidence.

## Research Brief

### Collaborative Research Plan

- Deliverable: a contract-level `/hive` skill and `/hiveworkflow` mode that
  coordinate multiple agents while preserving `/parallel`, `/workflow`,
  `/metacognition`, and `/introspect` boundaries.
- Core questions:
  - When do multi-agent systems outperform a single agent?
  - What coordination patterns are proven or documented: supervisor,
    handoffs, agents-as-tools, hierarchical crews, blackboards, debate,
    consensus, and arbitration?
  - What failure modes must minmaxing guard against?
  - Which existing repo surfaces should enforce the first slice?
- Stop condition: enough evidence to define static contracts and local fixtures
  without inventing a new runtime sidecar.

### Source Ledger

- Anthropic Engineering, "How we built our multi-agent research system":
  https://www.anthropic.com/engineering/multi-agent-research-system
  - Design implication: multi-agent systems are strongest for breadth-first,
    open-ended research where independent subagents use separate context
    windows, compress findings, and return evidence to a lead agent. Anthropic
    reports a 90.2% internal eval improvement for its research system, but also
    frames the benefit as task-dependent and token/tool-use driven.
- OpenAI, "A practical guide to building AI agents":
  https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/
  - Design implication: agent runs need loops and exit conditions; multi-agent
    orchestration can use manager patterns or decentralized handoffs, but
    complexity should be justified by workflow needs.
- OpenAI Agents SDK, "Agent orchestration":
  https://openai.github.io/openai-agents-python/multi_agent/
  - Design implication: "agents as tools" keeps one manager in control for
    synthesis and guardrails; handoffs are better when a specialist should own
    the next interaction. minmaxing should default to supervisor synthesis.
- CrewAI, "Processes":
  https://docs.crewai.com/en/concepts/processes
  - Design implication: hierarchical multi-agent work needs an explicit manager
    agent for planning, delegation, and validation. Consensus-style process is
    documented as planned rather than default, so minmaxing should not treat
    voting as enough proof.
- OpenAI Swarm repository:
  https://github.com/openai/swarm
  - Design implication: lightweight agents plus handoffs are useful educational
    primitives, but Swarm itself is stateless/client-side and positioned as
    educational, not a production governance layer.
- Li et al., "A survey on LLM-based multi-agent systems: workflow,
  infrastructure, and challenges" (Vicinagearth, 2024):
  https://link.springer.com/article/10.1007/s44336-024-00009-2
  - Design implication: MAS construction spans profile, perception,
    self-action, mutual interaction, and evolution; minmaxing's first slice
    should cover role profiles, interaction protocol, shared evidence, and
    verified learning without adding ungoverned evolution.

### Synthesis

Hive mode should be a coordination contract, not a replacement execution engine.
It should use `/metacognition` to decide whether hive coordination is useful,
`/parallel` when execution packets are independent and owned, `/workflow` for
normal file-changing execution, and `/introspect` as hard gate before packet
launch, after synthesis, after failed verification, and before push/ship.

The first slice should support:

- roles: queen/supervisor, scouts, builders, reviewers, verifier, scribe
- blackboard: durable artifact with claims, owners, evidence, conflicts,
  decisions, and locks
- swarm protocol: fan-out, sync, dissent, synthesis, arbitration, verify
- budgets: effective hive budget from capacity and independent role count
- safety: no peer agents mutate shared state without ownership/lock rules
- proof: static scorecard fixtures rejecting shallow hive claims

## Codebase Anchors

- `.claude/skills/parallel/SKILL.md` already defines packet DAG, ownership,
  sync barriers, run artifacts, aggregation, and independent verification.
- `.claude/skills/metacognition/SKILL.md` already routes tasks and computes
  effective budgets before execution.
- `.claude/skills/workflow/SKILL.md` owns the full file-changing lifecycle.
- `.claude/skills/introspect/SKILL.md` owns hard-gate self-audit.
- `scripts/parallel-capacity.sh --json` reports current capacity:
  `hardware_class=workstation`, `cores=16`, `ram_gb=32`,
  `recommended_ceiling=10`, `codex_max_threads=10`,
  `agent_teams_available=false`.
- `scripts/test-harness.sh`, `scripts/harness-eval.sh`, and
  `scripts/release-check.sh` are the static registration and release gates.

## Success Criteria

- [x] Add `.claude/skills/hive/SKILL.md` as a first-class multi-agent
      coordination skill.
- [x] Add `.claude/skills/hiveworkflow/SKILL.md` as an end-to-end workflow mode
      for hive-run planning, execution, aggregation, introspection, and verify.
- [x] Add `.claude/rules/hive.rules.md` with blackboard, role, consensus,
      arbitration, capacity, and verification rules.
- [x] Add `scripts/hive-scorecard.sh --fixtures --json` with stable rule IDs
      that reject weak hive artifacts.
- [x] Add green/red fixtures for role maps, blackboard state, consensus/dissent,
      capacity budgeting, shared-state locks, and verification.
- [x] Add static eval metadata/golden coverage and wire the gate into
      `scripts/harness-eval.sh`, `scripts/release-check.sh`, and
      `scripts/test-harness.sh`.
- [x] Register `/hive` and `/hiveworkflow` in README, CLAUDE.md, AGENTS.md,
      startup skill list, and skill counts.
- [x] Add a machine-readable `hive-run` sidecar contract, schema, fixtures, and
      `artifact-lint` support so durable hive runs can be checked beyond
      Markdown.
- [x] Add `scripts/hive-aggregate.sh --fixtures` and static eval/release wiring
      so `.taste/hive/{run_id}` folders are validated as aggregate hive runs.

## Scope

### In Scope

- Contract-level skills, rules, scorecard, fixtures, docs, eval, and harness
  wiring.
- Machine-readable `hive-run` sidecar and local aggregate validator.
- Local no-secret validation only.
- Clear relationship with `/parallel`, `/workflow`, `/metacognition`, and
  `/introspect`.

### Out of Scope

- New provider API integration.
- New long-running runtime service.
- Raw hidden chain-of-thought capture.
- Default use of experimental agent teams.
- Hermes registry changes unrelated to this task.

## Surgical Diff Discipline

- Smallest sufficient implementation: add two skills, one rule file, one
  scorecard, fixtures/eval metadata, and minimal docs/harness registration.
- No speculative runtime: do not build a hive daemon or sidecar until a later
  spec proves it.
- No drive-by refactors: leave existing `/parallel` machinery as the execution
  substrate instead of replacing it.
- Changed-line trace: every edit must trace to a success criterion above.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local implementation with two research sidecar agents
- Capacity evidence: `bash scripts/parallel-capacity.sh --json` on 2026-05-04
  reported `recommended_ceiling=10`, `codex_max_threads=10`,
  `hardware_class=workstation`, and `agent_teams_available=false`.
- Effective lanes: 3 of ceiling 10 for research/audit because the questions are
  independent; implementation stays local because docs/scripts/test wiring are
  tightly coupled.
- Critical path: research synthesis -> SPEC -> skill/rule/script/fixtures ->
  docs/startup/test-harness/eval/release wiring -> static verification.
- Agent wall-clock: optimistic 90 minutes / likely 2.5 hours / pessimistic
  4 hours.
- Agent-hours: 3-6 across local work plus research sidecars.
- Human touch time: none expected for this static slice.
- Calendar blockers: none unless release gate exposes unrelated drift.
- Confidence: medium-high; risk is broad registration drift and accidentally
  overlapping `/hive` with `/parallel`.

## Verification

- `bash -n scripts/*.sh`
- `bash scripts/hive-scorecard.sh --fixtures --json`
- `bash scripts/harness-eval.sh --json`
- `bash scripts/test-harness.sh`
- `bash scripts/release-check.sh --static-only`
- `git diff --check`

Verified locally on 2026-05-04:

- `bash -n scripts/hive-scorecard.sh scripts/metacognition-scorecard.sh scripts/harness-eval.sh scripts/test-harness.sh scripts/release-check.sh scripts/start-session.sh scripts/visualize-smoke.sh`: pass
- `bash scripts/hive-scorecard.sh --fixtures --json`: pass, 2 green fixtures
  accepted, 8 red fixtures rejected, no missing rules
- `bash scripts/metacognition-scorecard.sh --fixtures --json`: pass after
  adding `hive` as a metacognitive task class
- `bash scripts/harness-eval.sh --json`: pass, 14 tasks, 11 gates, 0
  mismatches
- `bash scripts/visualize-smoke.sh`: pass after updating stale 25-skill
  assertions to 27
- `bash scripts/test-harness.sh`: pass, 112 passed, 0 failed
- `bash scripts/release-check.sh --static-only`: pass, includes
  `HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`, 112 passed, 0 failed
- `git diff --check`: pass

Additional sidecar/aggregate completion slice on 2026-05-04:

- Added `schemas/hive-run.schema.json`.
- Extended `scripts/artifact-lint.sh` to validate `artifact_type=hive-run`
  sidecars and added green/red fixtures.
- Added `scripts/hive-aggregate.sh --fixtures` to validate
  `.taste/hive/{run_id}` folders with `hive-run.json` and optional
  `/parallel` aggregation.
- Added `evals/harness/tasks/m5-hive-aggregate.yaml` and
  `evals/harness/golden/m5-hive-aggregate.json`.
- Wired `hive-aggregate` into `scripts/harness-eval.sh`,
  `scripts/release-check.sh`, `scripts/test-harness.sh`, and hive docs.

Verified after sidecar/aggregate completion on 2026-05-04:

- `bash -n scripts/artifact-lint.sh scripts/hive-aggregate.sh scripts/hive-scorecard.sh scripts/harness-eval.sh scripts/test-harness.sh scripts/release-check.sh`: pass
- `bash scripts/artifact-lint.sh --fixtures`: pass, 4 green fixtures accepted,
  12 red fixtures rejected
- `bash scripts/hive-aggregate.sh --fixtures`: pass, 1 green fixture accepted,
  3 red fixtures rejected
- `bash scripts/hive-scorecard.sh --fixtures --json`: pass, 2 green fixtures
  accepted, 8 red fixtures rejected, no missing rules
- `bash scripts/harness-eval.sh --json`: pass, 15 tasks, 12 gates, 0
  mismatches
- `bash scripts/test-harness.sh`: pass, 113 passed, 0 failed
- `bash scripts/release-check.sh --static-only`: pass, includes
  `HARNESS_STATIC_CI=1 bash scripts/test-harness.sh`, 113 passed, 0 failed
- `git diff --check`: pass

## Rollback Plan

- Remove `.claude/skills/hive/`, `.claude/skills/hiveworkflow/`,
  `.claude/rules/hive.rules.md`, `scripts/hive-scorecard.sh`,
  `scripts/hive-aggregate.sh`, `schemas/hive-run.schema.json`,
  `.taste/fixtures/hive/`, `.taste/fixtures/hive-aggregate/`, hive
  artifact-lint fixtures, and hive eval task/golden files.
- Revert skill counts and startup/docs registration from 27 back to 25.
- Remove hive gate wiring from `scripts/harness-eval.sh`,
  `scripts/release-check.sh`, and `scripts/test-harness.sh`.
- Run `bash scripts/release-check.sh --static-only`.
