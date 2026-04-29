# Parallelism Rules

## Efficacy-First Default

- `MAX_PARALLEL_AGENTS` and Codex `max_threads` are ceilings, not quotas.
- Parallelize only when independent work packets materially reduce the critical path, improve context freshness, or isolate noisy evidence-gathering from the main thread.
- Prefer fewer high-signal agents over synthetic task splitting.
- If a task mostly lives in one file, one decision loop, or one tightly coupled context, keep it local.

## Effective Agent Budget

Choose an effective agent budget before spawning work:

```text
effective_agents = min(MAX_PARALLEL_AGENTS, independent_packets, supervisor_capacity, verification_capacity, hardware_recommended_ceiling)
```

Before dense work, get the hardware-aware ceiling:

```bash
bash scripts/parallel-capacity.sh --summary 2>/dev/null || true
```

Use this rough rubric:

- `1` agent: quick change, shared-context work, or a single tight implementation loop
- `2-3` agents: independent reads, focused tests, or bounded sidecar research
- `4-6` agents: medium feature work with disjoint files or a broad but coherent audit
- `7-10` agents: large audits, wide research, or clearly disjoint implementation packets with strong ownership

Do not inflate the packet count just to hit the ceiling.

## Hardware-Aware Capacity

- `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and the detected hardware profile are ceilings, not targets.
- Low capacity hosts should prefer local execution or at most 2 packets.
- Standard hosts should prefer 2-3 packets.
- High hosts should prefer 4-6 packets when ownership is disjoint.
- Workstations may use 7-10 packets only for large, disjoint, evidence-rich work that the supervisor can review.
- If the capacity profile cannot be produced, choose the conservative path and explain the downgrade.

## Execution Substrate Selector

- `local`: one tight reasoning loop, shared files, low hardware, or high coordination cost.
- `subagents`: default for bounded same-workspace packets with clear ownership.
- `parallel-instances`: only for large disjoint work where independent sessions or worktrees materially reduce elapsed time and aggregation is planned.
- `agent-teams`: opt-in experimental only when explicitly enabled and peer coordination is necessary.

Use `/parallel` when the whole workflow needs eligibility audit, capacity
profile, packet DAG, ownership matrix, sync barriers, and aggregate
verification. Use `/sprint` only for an execution wave inside an already
well-specified plan.

## Work Packet Requirements

Every delegated packet needs:

- a single owner
- owned files or surfaces
- an explicit do-not-touch list when overlap is risky
- dependency inputs or prerequisites
- a concise success definition
- the evidence format to return
- a freshness checkpoint that says when to stop and re-sync

If you cannot write this packet cleanly, the work is not ready for parallel execution.

## Thin Handoff Format

```text
Task: [specific outcome]
Why now: [why this packet matters]
Owned files/surfaces: [list]
Do not touch: [list]
Inputs: [spec, diff, facts, constraints]
Dependencies: [what must already be true]
Success: [definition of done]
Return: [summary, evidence, files touched]
Stop if: [overlap, missing dependency, conflicting evidence]
```

## Fresh Context Discipline

- Give each agent a thin, current brief instead of the whole parent thread.
- Reacquire context before acting if a dependency, spec, or owned file changes under the agent.
- Aggregate results in the supervisor; do not try to merge whole contexts together.

## Anti-Patterns

- Filling slots for the sake of utilization
- Splitting one tightly coupled file across multiple agents
- Delegating without ownership or a stop condition
- Passing the full parent context to every worker
- Running more agents than the supervisor can review
