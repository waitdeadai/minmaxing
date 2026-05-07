<!-- scorecard: green -->
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
- Reason: explicit user override requested a single local supervisor loop.

## Reasoning Budget
medium

## Evidence Required
- Commands Run: `bash scripts/metacognition-scorecard.sh --fixtures --json`
- Source Ledger: `.claude/skills/workflow/SKILL.md`, `.claude/skills/opusworkflow/SKILL.md`

## Metacognitive Audits
- Assumption audit: fallback is explicit, not silent.
- Source/evidence audit: route decision must name why `/opusworkflow` was not used.
- Scope audit: no provider runtime claims.
- Verification audit: static fixture proof only.
- Risk audit: avoid treating fallback as the new default.
- Estimate audit: one local lane is enough.

## Route Decision
- Route: `/workflow`
- Fallback status: `explicit_user_override`
- Reason: the user explicitly requested plain `/workflow`; otherwise use `/opusworkflow`.

## Confidence
- Level: medium
- Downgrade: local fallback does not prove Opus or MiniMax runtime identity.
