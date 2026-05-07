<!-- scorecard: red unresolved_blocker_closeout -->
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
- Reason: provider split was not checked.

## Reasoning Budget
medium

## Evidence Required
- Commands Run: `bash scripts/metacognition-scorecard.sh --fixtures --json`

## Metacognitive Audits
- Assumption audit: blocker: unresolved provider split.
- Source/evidence audit: missing OpusWorkflow doctor evidence.
- Scope audit: no explicit fallback approval.
- Verification audit: incomplete.
- Risk audit: silent fallback hides the default route.
- Estimate audit: unknown.

## Route Decision
- Route: `/workflow`
- Reason: easier than diagnosing Opus.

## Confidence
- Level: medium
- Downgrade: none.

## Outcome
PASS, ready to close out despite blocker: unresolved provider split.
