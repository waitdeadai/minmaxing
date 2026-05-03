<!-- scorecard: red raw_cot_dependency -->
# Metacognitive Route

## Task Class
verify

## Effective Parallel Budget
- MAX_PARALLEL_AGENTS: 10
- Codex max_threads: 10
- Hardware ceiling: 10
- Independent lanes available: 1
- Effective budget: 1
- Decision: local
- Reason: verifier reads one artifact.

## Evidence Required
- Commands Run: `bash scripts/test-harness.sh`

This mode depends on hidden CoT and requires raw hidden chain-of-thought to
score correctness.
