<!-- scorecard: green -->
# Metacognitive Route

## Task Class
hive

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
- Reason: role map, blackboard, and verifier lanes are independent enough to improve evidence.

## Reasoning Budget
high

## Evidence Required
- Commands Run: `bash scripts/hive-aggregate.sh --fixtures`
- Source Ledger: `.claude/skills/hiveworkflow/SKILL.md`, `.claude/skills/hive/SKILL.md`

## Metacognitive Audits
- Assumption audit: this is file-changing hive work, not read-only coordination.
- Source/evidence audit: hive artifact and aggregate verification are required.
- Scope audit: roles and ownership must be bounded before workers act.
- Verification audit: consensus does not replace `/verify`.
- Risk audit: avoid using hive only because lanes exist.
- Estimate audit: effective budget stays below the hardware ceiling.

## Route Decision
- Route: `/opusworkflow`
- Inner contract: `hiveworkflow`
- Reason: file-changing hive work needs the hybrid outer route plus hive lifecycle.

## Confidence
- Level: medium
- Downgrade: provider runtime identity is not proven by static fixture proof.
