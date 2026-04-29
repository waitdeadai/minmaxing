# SPEC: Hardware-Aware Parallel Mode And AgentFactory Capacity

## Problem Statement

Create a first-class `/parallel` mode where the main agent acts as orchestrator,
automatically detects development-host capacity, and chooses the smallest safe
execution substrate for dense work. Extend `/agentfactory` so Hermes agents and
Hermes fleets distinguish the developer machine from the target cloud/server
runtime, then derive concurrency budgets from the actual target runtime instead
of assuming a fixed local machine profile.

## Codebase Anchors

- `.claude/skills/workflow/SKILL.md` owns the full minmaxing lifecycle and must
  route dense work into `/parallel` without giving away taste, SPEC, security,
  or verification judgment.
- `.claude/skills/sprint/SKILL.md` is the lower-level execution-wave primitive;
  `/parallel` must be a whole-workflow orchestrator mode, not a rename of
  sprint.
- `.claude/skills/agentfactory/SKILL.md` creates Hermes agents and must require
  `development_host_profile`, `target_runtime_profile`, `host_capacity_profile`,
  `capacity_binding`, `concurrency_budget`, and runtime degradation policy.
- `.claude/rules/parallelism.rules.md` and `.claude/rules/delegation.rules.md`
  define effective budgets, thin handoffs, and non-delegable decisions.
- `scripts/start-session.sh`, `scripts/test-harness.sh`, and smoke scripts are
  the durable guardrails that keep skills and docs honest.
- `.codex/config.toml` already sets `[agents].max_threads = 10`; `/parallel`
  must treat this as a ceiling, not a target.

## Success Criteria

- [ ] Add `.claude/skills/parallel/SKILL.md` as a self-contained whole-workflow
      mode with eligibility audit, hardware capacity profile, execution
      substrate selector, packet DAG, ownership matrix, sync barriers, worker
      result schema, hard introspection, and verification protocol.
- [ ] Add `scripts/parallel-capacity.sh` that reports CPU/RAM, hardware class,
      `MAX_PARALLEL_AGENTS`, Codex `max_threads`, recommended ceiling, and
      safe substrate guidance in markdown and JSON.
- [ ] Add `scripts/parallel-smoke.sh` and wire it into
      `scripts/test-harness.sh` so regressions in `/parallel` and
      AgentFactory capacity awareness fail fast.
- [ ] Update `/workflow`, `/autoplan`, `/sprint`, `/introspect`, `/verify`,
      parallelism rules, and delegation rules so `/parallel` is automatically
      considered for dense work but downgraded when unsafe.
- [ ] Update `/agentfactory` so every Hermes agent/fleet includes
      `development_host_profile`, `target_runtime_profile`,
      `host_capacity_profile`, `capacity_binding`, `concurrency_budget`,
      runtime capacity fields, degradation policy, introspection checks, and
      verification checks.
- [ ] Block `active` production readiness when the target runtime differs from
      the development host and no target runtime capacity evidence is present.
- [ ] Update `README.md`, `CLAUDE.md`, `AGENTS.md`, and
      `scripts/start-session.sh` to register `/parallel` and document
      hardware-aware automatic use.
- [ ] Verification passes: `bash -n` for changed scripts,
      `bash scripts/parallel-capacity.sh --json`, `bash scripts/parallel-smoke.sh`,
      `bash scripts/agentfactory-smoke.sh`, `bash scripts/test-harness.sh`, and
      `git diff --check`.

## Scope

### In Scope

- New `/parallel` skill and smoke coverage.
- Host-capacity detection script for repeatable development-host concurrency
  decisions.
- Existing skill/rule/docs updates that make `/parallel` first-class.
- AgentFactory/Hermes schema and runtime-contract updates for capacity-aware
  agents and fleets that may deploy to a different cloud/server/runtime than
  the developer PC.
- Harness tests that prevent stale skill counts and capacity drift.

### Out of Scope

- Enabling experimental Claude Code agent teams by default.
- Implementing a daemon that launches uncontrolled external Claude sessions.
- Publishing private REVCLI runtime code, customer agents, customer data, or
  commercial implementation packs.
- Rewriting the whole workflow harness beyond the minimal `/parallel` slice.

## Surgical Diff Discipline

- Smallest sufficient implementation: add one skill, two scripts, and targeted
  references in existing skills/rules/docs/tests.
- No speculative abstractions: no general scheduler, no recursive swarm engine,
  no default agent-team dependency.
- No drive-by refactors: leave unrelated skill behavior and docs untouched.
- Changed-line trace: every meaningful change maps to a success criterion in
  this SPEC or to harness cleanup required by the new skill count.

## Implementation Plan

### Phase 1: Parallel Contract Foundation

- [ ] Write `.claude/skills/parallel/SKILL.md` with explicit phase sequence,
      auto-use policy, capacity profile, substrate selector, packet contract,
      ownership model, barriers, aggregation, verification, and closeout.
- [ ] Add `scripts/parallel-capacity.sh` and `scripts/parallel-smoke.sh`.

### Phase 2: Harness Integration

- [ ] Update workflow/autoplan/sprint/introspect/verify skills to reference
      `/parallel` where their existing responsibilities intersect.
- [ ] Update parallelism and delegation rules to make hardware-aware capacity
      and substrate choice explicit.
- [ ] Update start-session and test-harness counts, registrations, and smoke
      checks.

### Phase 3: AgentFactory Capacity Integration

- [ ] Add capacity-aware fields and checks to the AgentFactory manifest schema,
      runtime JSON, deploy docs, verify docs, introspection gate, and failure
      catalog.
- [ ] Update `scripts/agentfactory-smoke.sh` fixtures so capacity fields are
      required and validated.

### Phase 4: Documentation And Verification

- [ ] Update README, CLAUDE, and AGENTS with `/parallel`, the automatic routing
      contract, and Hermes fleet capacity requirements.
- [ ] Run syntax checks, smoke tests, full harness, and diff hygiene.
- [ ] Archive this active SPEC on verified closeout.

## Verification

- `/parallel` skill exists and contains: `Parallel Eligibility Audit`,
  `Hardware Capacity Profile`, `Execution Substrate Selector`, `Packet DAG`,
  `Ownership Matrix`, `Sync Barrier`, `Worker Result Schema`,
  `parallel-instances`, `subagents`, `agent teams are opt-in experimental`,
  `MAX_PARALLEL_AGENTS`, and `agentfactory`.
- `parallel-capacity.sh --json` emits parseable JSON with required keys and a
  positive `recommended_ceiling`.
- `parallel-smoke.sh` passes and is invoked by `test-harness.sh`.
- `agentfactory-smoke.sh` fails fixtures without capacity fields and passes the
  positive capacity-aware fixture.
- AgentFactory contracts explicitly distinguish `development_host_profile`,
  `target_runtime_profile`, and `capacity_binding`.
- README, CLAUDE, AGENTS, and start-session all register `/parallel`.
- Full harness passes with updated 22-skill expectations.

## Rollback Plan

1. Remove `.claude/skills/parallel/SKILL.md`.
2. Remove `scripts/parallel-capacity.sh` and `scripts/parallel-smoke.sh`.
3. Revert targeted `/parallel` and capacity-aware changes in skills, rules,
   docs, and smoke tests.
4. Restore prior `SPEC.md` from `.taste/specs/` if this implementation is
   abandoned.
