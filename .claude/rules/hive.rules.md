# Hive Rules

Hive coordination is governed collective work, not a vibe.

## Role Discipline

- Every hive run must name a queen/supervisor.
- Every non-supervisor role needs a purpose, inputs, output format, stop
  condition, and verification path.
- Do not spawn roles that have no independent evidence to return.
- Role summaries are claims until verified by the queen/supervisor.

## Blackboard Discipline

- Non-trivial hive runs must maintain a visible blackboard artifact.
- Every claim needs owner, evidence, status, conflicts, and lock or merge-barrier
  state.
- Shared-state edits require owned files, locks, or merge barriers.
- Do not let agents update durable memory, prompt contracts, or shared state
  from unverified claims.

## Dissent And Synthesis

- Consensus is not evidence.
- Non-trivial synthesis needs an explicit dissent, skeptic, reviewer, or
  verifier lane.
- If agents agree without evidence, downgrade confidence or rerun with an
  adversarial role.
- The queen/supervisor arbitrates conflicts using evidence or blocks the run.

## Capacity

- `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and hardware ceiling are ceilings,
  not quotas.
- Compute `effective_hive_budget` before spawning roles.
- Adding agents stops helping when supervisor review, blackboard merge capacity,
  verification, shared files, credentials, or sync barriers become bottlenecks.
- Never claim linear hive scaling or that more agents means more quality.

## Integration Boundary

- `/hive` coordinates roles and blackboard state.
- `/hiveworkflow` runs the full lifecycle when hive coordination changes files.
- `/parallel` remains the worker packet, ownership, sidecar, and aggregation
  substrate.
- `/workflow` remains the default file-changing lifecycle.
- `/introspect` and `/verify` remain hard gates; hive consensus cannot replace
  either.
