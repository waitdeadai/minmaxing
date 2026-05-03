<!-- scorecard: green -->
# Metacognitive Route

## Task Class
workflow

## Capacity Evidence
- Source: `bash scripts/parallel-capacity.sh --json`
- MAX_PARALLEL_AGENTS: unknown
- Codex max_threads: 10
- Hardware ceiling: 10

## Effective Parallel Budget
- MAX_PARALLEL_AGENTS: unknown
- Codex max_threads: 10
- Hardware ceiling: 10
- Independent lanes available: 1
- Effective budget: 1
- Decision: local
- Reason: shared workflow and introspection contract edits are tightly coupled.

## Reasoning Budget
high

## Evidence Required
- Commands Run: `bash scripts/test-harness.sh`
- Source Ledger: `SPEC.md`, `.claude/skills/workflow/SKILL.md`

## Metacognitive Audits
- Assumption audit: active spec is the contract.
- Source/evidence audit: repo files and command evidence are required.
- Scope audit: no provider API changes.
- Verification audit: static harness must pass.
- Risk audit: avoid overbuilding a second workflow.
- Estimate audit: effective lanes stay below capacity ceiling.

## Route Decision
- Route: `/workflow`
- Reason: file-changing harness contract work.

## Confidence
- Level: medium
- Downgrade: runtime provider behavior is out of scope.
