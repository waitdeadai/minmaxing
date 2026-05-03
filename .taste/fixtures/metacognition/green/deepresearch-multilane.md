<!-- scorecard: green -->
# Metacognitive Route

## Task Class
deepresearch

## Capacity Evidence
- Source: `bash scripts/parallel-capacity.sh --json`
- MAX_PARALLEL_AGENTS: 10
- Codex max_threads: 10
- Hardware ceiling: 10

## Effective Parallel Budget
- MAX_PARALLEL_AGENTS: 10
- Codex max_threads: 10
- Hardware ceiling: 10
- Independent lanes available: 3
- Effective budget: 3
- Decision: subagents
- Reason: official docs, academic papers, and local repo audit are independent evidence tracks.

## Reasoning Budget
xhigh

## Evidence Required
- Source Ledger: official docs, papers, local repo files
- Commands Run: `rg -n "introspect|deepresearch" .`

## Metacognitive Audits
- Assumption audit: external claims remain candidates until cited.
- Source/evidence audit: each branch needs cited sources.
- Scope audit: research only.
- Verification audit: final plan needs pre-plan introspection.
- Risk audit: avoid smoothing conflicting evidence.
- Estimate audit: three lanes are below the ceiling and map to distinct questions.

## Route Decision
- Route: `/deepresearch`
- Reason: strategic architecture research.

## Confidence
- Level: medium
- Downgrade: public sources do not expose proprietary lab internals.
