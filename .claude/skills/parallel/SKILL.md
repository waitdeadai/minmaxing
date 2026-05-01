---
name: parallel
description: Run dense minmaxing work as a hardware-aware, main-orchestrated parallel workflow with bounded packets, explicit ownership, sync barriers, aggregation, and independent verification.
argument-hint: [dense task]
disable-model-invocation: true
---

# /parallel

Run a hardware-aware parallel workflow for:

$ARGUMENTS

`/parallel` is a whole-workflow acceleration mode. The main agent remains the orchestrator and keeps taste alignment, research sufficiency, architecture, SPEC ownership, security decisions, aggregation, hard introspection, and final verification. Workers only execute bounded packets with explicit ownership.

This is not `/sprint`. `/sprint` is an execution-wave primitive. `/parallel`
decides whether the whole request merits parallel orchestration, chooses the
execution substrate, writes the packet DAG, supervises sync barriers, and
verifies the aggregate result against the active contract.

## Non-Negotiable Contract

- Never parallelize just to use slots.
- Never delegate taste decisions, `SPEC.md` creation, architecture, security,
  quality-gate enforcement, final verification, or closeout judgment.
- Always run a Parallel Eligibility Audit before spawning or instructing
  parallel work.
- Always run a Hardware Capacity Profile before selecting a budget.
- Always record an `Agent-Native Estimate` before freezing the packet plan.
- Use the smallest effective budget that shortens the critical path.
- Use subagents by default for bounded same-workspace sidecar packets.
- Use parallel-instances only when disjoint ownership, speed need, and
  aggregation evidence justify the extra coordination cost.
- Treat agent teams as opt-in experimental. Agent teams are opt-in experimental
  and must not be required for default `/parallel` behavior.
- Record all packet ownership, dependencies, sync barriers, and returned
  evidence in a workflow artifact.
- Estimate elapsed time from the longest dependency path, including sync
  barriers, aggregation, verification, review, and rework risk.
- Block when workers would touch the same files or make conflicting authority
  claims.
- Run `/introspect` as a hard gate before freezing the packet plan, after
  aggregation, after failed verification, and before any push/ship decision.
- Run `/verify` against `SPEC.md` after aggregation. Worker success is not final
  success.
- Keep `.minimaxing/state/CURRENT.md` or the workflow artifact current enough
  to survive `/compact`.

## Auto-Use Policy

`/workflow` should automatically consider `/parallel` when all conditions hold:

- The task is dense: research-heavy, audit-heavy, broad verification, or
  implementation with at least two independent packets.
- The expected critical-path reduction is larger than coordination cost.
- File, surface, or evidence ownership can be written cleanly.
- The host capacity profile supports at least two safe concurrent packets.
- The main agent has enough review capacity to inspect returned evidence.

Downgrade to normal `/workflow` or local execution when:

- The task is one tight reasoning loop.
- The task mostly touches one file or one shared context.
- Dependencies are unclear or workers would need constant back-and-forth.
- Verification cannot be split or aggregated safely.
- Host capacity, memory pressure, or tooling limits make parallelism noisy.

When the user explicitly requests parallel mode, still run the eligibility
audit. If the audit fails, explain the downgrade and proceed with the safest
non-parallel path.

## Phase 0: Taste Gate

1. Read `taste.md` and `taste.vision`.
2. Rehydrate current state:

```bash
bash scripts/state.sh status 2>/dev/null || true
```

3. Check that acceleration does not conflict with project taste. Speed must not
   outrank evidence, safety, or surgical diffs.
4. Record the decision in the workflow artifact.

Hard gate: if the task conflicts with taste or open-core boundaries, stop or
ask for an explicit alignment decision.

## Phase 1: Parallel Eligibility Audit

Before research, planning, or spawning, answer:

| Question | PASS Condition | BLOCK/DOWNGRADE Condition |
|----------|----------------|---------------------------|
| Are there at least two independent packets? | Distinct files, surfaces, research branches, tests, or audits. | One shared file/context/reasoning loop. |
| Does parallelism shorten the critical path? | Workers can return useful evidence before the main is blocked. | Coordination cost exceeds speedup. |
| Can ownership be written explicitly? | Each packet has owned files/surfaces and do-not-touch list. | Ownership overlaps or is unknown. |
| Can dependencies be expressed as a DAG? | Packet order and sync barriers are clear. | Circular or hidden dependencies. |
| Can the main verify the aggregate? | `SPEC.md` criteria and evidence commands exist or can be written. | Final correctness depends on worker trust. |
| Is the host capacity sufficient? | Recommended ceiling is at least 2 and tools are available. | Capacity script says local-only or degraded host. |

Decision values:
- `PARALLEL_READY`: continue.
- `LOCAL_BETTER`: use normal `/workflow`.
- `NEEDS_SPEC_FIRST`: write or update `SPEC.md` before packetizing.
- `BLOCKED`: stop because ownership, safety, or verification cannot be proven.

## Phase 2: Hardware Capacity Profile

Run:

```bash
bash scripts/parallel-capacity.sh --json 2>/dev/null || bash scripts/detect-hardware.sh 2>/dev/null || true
```

Record:
- CPU cores
- RAM GB
- hardware class: `low`, `standard`, `high`, or `workstation`
- `MAX_PARALLEL_AGENTS`
- Codex `max_threads`
- recommended ceiling
- default substrate
- whether experimental agent teams are enabled

Budget formula:

```text
effective_parallel_budget = min(
  capacity.recommended_ceiling,
  independent_packets,
  supervisor_review_capacity,
  verification_capacity
)
```

Hardware guidance:
- `low`: keep local or use at most 2 packets.
- `standard`: use 2-3 packets when ownership is crisp.
- `high`: use up to 4-6 packets for independent work.
- `workstation`: use up to 7-10 only for large, disjoint, evidence-rich work.

Hard gate: if the capacity profile cannot be produced, assume conservative
`standard` only when the task is low risk. Otherwise downgrade.

## Phase 3: Execution Substrate Selector

Choose one substrate and justify it:

| Substrate | Use When | Do Not Use When |
|-----------|----------|-----------------|
| `local` | One tight reasoning loop, shared files, low hardware, or fast direct edit. | Multiple independent evidence branches are waiting. |
| `subagents` | Default for bounded same-workspace research, audit, implementation, and review packets. | Packets need independent working trees or incompatible tool states. |
| `parallel-instances` | Large disjoint work where separate sessions, shells, worktrees, or independent Claude/Codex instances materially reduce elapsed time. | Same files, permission storm, unowned state, or weak aggregation plan. |
| `agent-teams` | Opt-in experimental peer coordination when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and the task genuinely needs agents coordinating with each other. | Default use, production-critical path without fallback, or untested team behavior. |

Selection rule:
- Prefer `local` for small or coupled work.
- Prefer `subagents` for most parallel work.
- Promote to `parallel-instances` only when the packet DAG is wide, ownership is
  disjoint, and speed need justifies separate contexts.
- Promote to `agent-teams` only with explicit experimental opt-in and fallback.

## Phase 4: Deep Research And Code Audit

Follow the same research discipline as `/workflow`:

- Draft a collaborative research plan before the first search wave.
- Use search -> read -> refine loops.
- Keep a source ledger with cited, reviewed-but-not-cited, and rejected sources.
- Run code audit before planning edits.
- Use the capacity profile as a ceiling, not a target.
- Keep the main agent responsible for research sufficiency.

Parallel research packets must be distinct. Do not assign multiple workers to
the same broad question.

## Phase 5: Packet DAG And Ownership Matrix

Create a durable artifact:

```bash
mkdir -p .taste/workflow-runs
STAMP="$(date +%Y%m%d-%H%M%S)"
PARALLEL_ARTIFACT=".taste/workflow-runs/${STAMP}-parallel.md"
```

Required section order:

```markdown
# Parallel Run: {task}

## Task
## Taste Gate
## Parallel Eligibility Audit
## Hardware Capacity Profile
## Execution Substrate Selector
## Agent-Native Estimate
## Deep Research Brief
## Code Audit
## Pre-Plan Introspection
## SPEC Decision
## Packet DAG
## Ownership Matrix
## Sync Barriers
## Worker Packets
## Aggregation Notes
## Post-Aggregation Introspection
## Independent Verification Evidence
## Closeout
```

### Packet DAG

```markdown
| Packet ID | Purpose | Depends On | Can Run With | Blocks | Estimated Duration | Confidence | Status |
|-----------|---------|------------|--------------|--------|--------------------|------------|--------|
| P1 | ... | none | P2, P3 | B1 | 45-90m | medium | pending |
```

### Agent-Native Estimate

```markdown
## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local | subagents | parallel-instances | agent-teams-experimental
- Capacity evidence: scripts/parallel-capacity.sh --json, Codex max_threads, MAX_PARALLEL_AGENTS
- Effective lanes: N of ceiling M
- Critical path: P1 -> B1 -> P4 -> verification
- Agent wall-clock: optimistic / likely / pessimistic
- Agent-hours: total active work across all packets
- Human touch time: review, approval, credentials, product decisions
- Calendar blockers: CI queue, deploy window, external account setup, rate limits, business-hours dependency
- Confidence: high | medium | low, with downgrade reason
- Human-equivalent baseline: optional secondary comparison only
```

Calculate elapsed time from the longest dependency path, not total packet
effort. Show when adding lanes stops helping because the supervisor, verifier,
shared files, sync barriers, CI, credentials, or deploy windows become the
bottleneck.

### Ownership Matrix

```markdown
| Packet ID | Owner/Substrate | Owned Files/Surfaces | Do Not Touch | Shared Inputs | Conflict Risk |
|-----------|-----------------|----------------------|--------------|---------------|---------------|
| P1 | subagent | path/a | path/b | SPEC.md | low |
```

### Sync Barrier

```markdown
| Barrier ID | Waits For | Main-Agent Check | Continue When | Stop When |
|------------|-----------|------------------|---------------|-----------|
| B1 | P1, P2 | inspect evidence and diff | all pass | conflict, stale context, failed packet |
```

Hard gate: do not launch workers until the DAG, ownership matrix, and first
barrier are written.

## Phase 6: SPEC.md And Worker Packet Contracts

If files will change, `SPEC.md` must exist before worker execution. The main
agent writes or updates `SPEC.md`; workers do not.

Every packet uses this contract:

```text
Packet ID: [P#]
Task: [specific outcome]
Why now: [why this shortens the critical path]
Substrate: [local|subagents|parallel-instances|agent-teams]
Owned files/surfaces: [exact list]
Do not touch: [exact list]
Inputs: [SPEC.md section, artifact section, source refs, constraints]
Dependencies: [packets/barriers required first]
Estimated duration: [optimistic / likely / pessimistic]
Estimate confidence: [high|medium|low with reason]
Success: [objective definition of done]
Verification to run: [commands or inspection]
Return: [Worker Result Schema]
Stop if: [overlap, stale spec, missing dependency, conflicting evidence, auth risk]
```

Worker Result Schema:

```markdown
## Worker Result: P#

- Status: success|failed|blocked|partial
- Summary:
- Files inspected:
- Files changed:
- Commands run:
- Evidence:
- Assumptions:
- Risks:
- Conflicts or stale context:
- Follow-up needed:
```

Workers must stop instead of improvising when:
- their owned files changed unexpectedly
- `SPEC.md` conflicts with packet instructions
- they need a permission not granted in the packet
- they find a security, data, or irreversible-action risk
- they need to touch a do-not-touch file
- verification fails and the fix would broaden scope

## Phase 6.5: Introspect Hard Gate

Before aggregation is considered ready, run `/introspect`.

Parallel-specific checks:
- Did we choose the right substrate, or was parallelism theatrical?
- Did any packet exceed the hardware capacity profile or configured ceiling?
- Did any worker touch unowned files or shared state?
- Did any worker rely on stale context after a sync barrier?
- Did any worker claim success without evidence?
- Did workers produce split-brain decisions or conflicting assumptions?
- Did the main delegate architecture, security, SPEC, or verification judgment?
- Are packet results traceable back to `SPEC.md`?
- Does the Agent-Native Estimate use critical-path math instead of summed
  packet effort or linear lane scaling?
- Did the estimate include verification, aggregation, review, blockers, and
  confidence labels?
- Did parallel-instances or agent teams add unverified behavior?
- Does any Hermes/agentfactory output lack `development_host_profile`,
  `target_runtime_profile`, `capacity_binding`, or `concurrency_budget` when
  the task creates agents or fleets?

Decision:
- `PASS`: proceed to independent verification.
- `FIX_REQUIRED`: fix packet outputs or aggregation.
- `REPLAN_REQUIRED`: rewrite the packet plan or SPEC.
- `BLOCKED`: stop and ask for operator input or downgrade.

## Phase 7: Independent Verification

Run `/verify` against `SPEC.md` after aggregation. Verification must inspect the
aggregate result, not just worker summaries.

Required parallel verification:

| Check | Evidence |
|-------|----------|
| Packet completion | Every packet has a Worker Result Schema entry. |
| Ownership compliance | Changed files match the ownership matrix. |
| Conflict check | No same-file collision or unresolved split-brain claim. |
| Barrier check | Sync barriers were honored before dependent work. |
| SPEC trace | Meaningful changes trace to success criteria. |
| Capacity check | Effective budget did not exceed profile or configured ceiling. |
| Substrate check | Chosen substrate matched the documented reason. |
| Aggregate test | Final commands or inspection prove the whole result works. |

If verification fails, run `/introspect after-test-failure`, fix only the
minimal failing slice, and re-verify.

## Phase 8: Closeout

Closeout must include:
- eligibility decision and whether parallelism was used or downgraded
- capacity profile summary
- selected substrate and effective budget
- Agent-Native Estimate summary, including critical path, wall-clock range,
  agent-hours, blockers, confidence, and whether actual elapsed timing was
  recorded
- packet count and outcomes
- changed files by packet
- verification result and isolation metadata
- residual risks
- whether `SPEC.md` was archived

If `/parallel` created or updated Hermes agents through `/agentfactory`, closeout
must also include each agent's `development_host_profile`,
`target_runtime_profile`, `host_capacity_profile`, `capacity_binding`,
`concurrency_budget`, runtime degradation policy, and kill-switch verification
result.

## AgentFactory And Hermes Integration

When `/parallel` is used to create Hermes agents, agent fleets, or enterprise
workflow agents:

- `/agentfactory` remains the agent-generation authority.
- `/parallel` may accelerate repo audit, runtime audit, documentation mapping,
  capability review, and verification packet collection.
- The main agent must still own the Hermes manifest, Hermes SPEC, authority
  model, security review, and registry decision.
- Every generated Hermes agent or fleet must include `development_host_profile`,
  `target_runtime_profile`, `host_capacity_profile`, `capacity_binding`,
  `concurrency_budget`, maximum parallel runs, queue/backpressure behavior, and
  degrade policy.
- Local `scripts/parallel-capacity.sh` output describes the development host
  unless the target runtime is explicitly local.
- A Hermes fleet must not assume the developer machine can run every agent at
  once, and it must not assume a cloud/server target has the same specs as the
  dev PC. Target runtime capacity must be measured, read from infrastructure
  config/provider limits, or explicitly declared by the operator.

## Anti-Patterns

- Using all slots because they exist.
- Splitting one file across multiple workers.
- Treating worker output as verified truth.
- Letting workers write or replace `SPEC.md`.
- Using parallel-instances without separate ownership or aggregation.
- Enabling experimental agent teams as a default dependency.
- Ignoring RAM/CPU and blaming model quality for host overload.
- Creating Hermes fleets without capacity budgets or kill switches.
