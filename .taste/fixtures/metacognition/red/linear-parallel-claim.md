<!-- scorecard: red linear_parallel_claim -->
# Metacognitive Route

## Task Class
parallel

## Capacity Evidence
- Source: `bash scripts/parallel-capacity.sh --json`

## Effective Parallel Budget
- MAX_PARALLEL_AGENTS: 10
- Codex max_threads: 10
- Hardware ceiling: 10
- Independent lanes available: 10
- Effective budget: 10
- Decision: parallel
- Reason: 10 agents means 10x faster.

## Evidence Required
- Commands Run: `bash scripts/parallel-smoke.sh`
