# Estimation Rules

## Agent-Native Default

For every meaningful planning workflow, estimate elapsed effort in
agent-native wall-clock terms before the plan or `SPEC.md` is frozen.

Use human-equivalent estimates only as a secondary comparison. Do not present
"6 weeks", "2 engineer-months", or similar human-calendar estimates as the
primary answer unless the estimate type is explicitly `human-equivalent` or
`blocked/unknown`.

Required estimate fields:

- `agent_wall_clock`: expected elapsed time on the chosen execution topology.
- `agent_hours`: total active work across all lanes.
- `human_touch_time`: operator review, approval, credentials, product calls, or
  other human participation.
- `calendar_blockers`: CI queues, deploy windows, account setup, rate limits,
  business-hours dependencies, procurement, or unavailable credentials.
- `critical path`: the longest dependency chain that determines elapsed time.
- `confidence`: high, medium, or low with a downgrade reason when evidence is
  weak.

## Estimate Types

- `agent-native wall-clock`: default for minmaxing plans. It estimates elapsed
  time in the actual harness topology.
- `human-equivalent`: optional secondary comparison for stakeholder intuition.
- `blocked/unknown`: use when credentials, product decisions, target runtime,
  source access, or verification gates are missing enough evidence to estimate
  honestly.

Every estimate must state which type it is.

## Capacity Evidence

Before choosing lanes for non-trivial work, read current capacity evidence:

```bash
bash scripts/parallel-capacity.sh --json 2>/dev/null || true
```

Use `MAX_PARALLEL_AGENTS`, Codex `max_threads`, hardware class, recommended
ceiling, and substrate availability as ceilings, not targets. The current
capacity profile constrains what can run concurrently; it does not prove that
more lanes will reduce elapsed time.

## Critical-Path Math

Estimate project elapsed time from the longest dependency path:

```text
agent_wall_clock = longest_path(packet_duration + sync_barrier + verification_gate + rework_risk)
```

Do not sum all packet durations when packets can run in parallel. Do not divide
human weeks by the lane count. Estimate the actual packet DAG and name the
sync barriers that stop additional lanes from helping.

Examples of bottlenecks that cap speedup:

- supervisor review capacity
- verifier capacity
- shared files or shared context
- CI runtime
- deploy windows
- credentials or approvals
- target runtime capacity
- rate limits
- one critical architecture decision that must stay local

## Stable Estimate Block

Every non-trivial plan should include:

```markdown
## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local | subagents | parallel-instances | agent-teams-experimental
- Capacity evidence: scripts/parallel-capacity.sh --json, Codex max_threads, MAX_PARALLEL_AGENTS
- Effective lanes: N of ceiling M
- Critical path: P1 -> P4 -> P7
- Agent wall-clock: optimistic / likely / pessimistic
- Agent-hours: total active work across all lanes
- Human touch time: review, approval, credentials, product decisions
- Calendar blockers: CI queue, deploy window, external account setup, rate limits, business-hours dependency
- Confidence: high | medium | low, with downgrade reason
- Human-equivalent baseline: optional secondary comparison only
```

For tiny local tasks, the block can be collapsed to one concise sentence, but
it must still be agent-native and must not hide verification or review time.

## Forbidden Estimate Patterns

Return `FIX_REQUIRED` during planning or introspection when an estimate:

- gives human time as the default and omits agent-native wall-clock
- uses a human-equivalent baseline as the only estimate
- says or implies linear scaling, such as "10 agents means 10x faster"
- divides human weeks by lane count
- assumes 24/7 parallelism without dependencies, ownership, capacity, and
  verification support
- omits verification, review, aggregation, or sync-barrier time
- hides human blockers, external credentials, CI queues, or deploy windows
- omits confidence labels or gives false precision
- treats development-host capacity as cloud/server/fleet production capacity
  without target runtime evidence

## Calibration Loop

Do not invent calibration numbers. Learn from real workflow artifacts.

Before execution, workflow artifacts should record the Agent-Native Estimate.
After verification, workflow artifacts should record:

- `started_at`
- `plan_frozen_at`
- `implementation_started_at`
- `verification_completed_at`
- `closed_at`
- effective lanes used
- failed verification count
- human blocker minutes if known

Use `scripts/estimate-history.sh` to summarize observed estimates versus
actual elapsed time from `.taste/workflow-runs/`.
