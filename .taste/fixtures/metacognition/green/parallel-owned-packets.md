<!-- scorecard: green -->
# Metacognitive Route

## Task Class
parallel

## Capacity Evidence
- Source: `bash scripts/parallel-capacity.sh --json`
- MAX_PARALLEL_AGENTS: 10
- Codex max_threads: 10
- Hardware ceiling: 10

## Effective Parallel Budget
- MAX_PARALLEL_AGENTS: 10
- Codex max_threads: 10
- Hardware ceiling: 10
- Independent lanes available: 4
- Effective budget: 4
- Decision: parallel
- Reason: packet DAG has disjoint docs, fixtures, scorecard, and smoke-test ownership.

## Reasoning Budget
high

## Evidence Required
- Commands Run: `bash scripts/parallel-aggregate.sh .taste/parallel/run`
- Verification Evidence: worker results and parent aggregation

## Metacognitive Audits
- Assumption audit: each packet has an owner.
- Source/evidence audit: worker claims require command evidence.
- Scope audit: no cross-owned edits.
- Verification audit: aggregation must pass before closeout.
- Risk audit: reject failed or unverified worker results.
- Estimate audit: effective lanes are based on packet DAG, not max slot filling.

## Route Decision
- Route: `/parallel`
- Reason: dense implementation with owned packets and aggregate verification.

## Confidence
- Level: medium
- Downgrade: final confidence depends on aggregation output.
