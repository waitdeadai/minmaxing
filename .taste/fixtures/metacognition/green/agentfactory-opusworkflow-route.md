<!-- scorecard: green -->
# Metacognitive Route

## Task Class
agentfactory

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
- Reason: Hermes runtime contract, manifest, and registry edits need one supervising route.

## Reasoning Budget
high

## Evidence Required
- Commands Run: `bash scripts/agentfactory-smoke.sh`
- Source Ledger: `.claude/skills/agentfactory/SKILL.md`, `SPEC.md`

## Metacognitive Audits
- Assumption audit: Hermes generation is mutating specialist work.
- Source/evidence audit: AgentFactory contract and static smoke are required.
- Scope audit: no production runtime authority without proof.
- Verification audit: generated agent claims need independent verification.
- Risk audit: avoid direct specialist mutation outside the hybrid provider split.
- Estimate audit: one supervisor lane is safer than parallel manifest edits.

## Route Decision
- Route: `/opusworkflow`
- Inner contract: `agentfactory`
- Reason: governed Hermes work mutates files and must inherit OpusWorkflow.

## Confidence
- Level: medium
- Downgrade: runtime model identity remains account-dependent.
