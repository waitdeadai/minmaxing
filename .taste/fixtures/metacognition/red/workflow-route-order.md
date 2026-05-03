<!-- scorecard: red workflow_route_order -->
# Workflow Run: Bad Route Order

## Task
Misordered workflow artifact.

## Taste Gate
Aligned.

## Research Brief
Research happened before route steering.

## Metacognitive Route
## Task Class
workflow

## Capacity Evidence
- Source: `bash scripts/parallel-capacity.sh --json`
- MAX_PARALLEL_AGENTS: 10
- Codex max_threads: 10
- Hardware ceiling: 10

## Effective Parallel Budget
- MAX_PARALLEL_AGENTS: 10
- Codex max_threads: 10
- Hardware ceiling: 10
- Independent lanes available: 1
- Effective budget: 1
- Decision: local
- Reason: one lane.

## Evidence Required
- Commands Run: `bash scripts/metacognition-scorecard.sh --fixtures --json`

## Route Decision
- Route: `/workflow`
- Reason: file-changing task.

## Confidence
- Level: medium
- Downgrade: none.

## Introspection
pre-plan PASS.
