<!-- scorecard: red command_boundary_confusion -->
# Metacognitive Route

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
- Reason: one steering lane is enough.

## Evidence Required
- Commands Run: `bash scripts/metacognition-scorecard.sh --fixtures --json`

## Route Decision
- Route: `/workflow`
- Reason: metacognition satisfies the required `/introspect` hard gate, so the workflow can skip introspection later.

## Confidence
- Level: medium
- Downgrade: none.
