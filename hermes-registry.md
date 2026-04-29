# Hermes Registry

## Registry Contract
- Source of truth for Hermes agents created by `/agentfactory`.
- Status values: `active`, `deprecated`, `experimental`, `paused`.
- Every active agent must link to manifest, spec, verification, kill-switch evidence, and runtime evidence.
- Registry updates require `/agentfactory` or an explicit operator-approved maintenance change.
- The registry tracks agents that exist in this repo; external private consumer repos may keep their own registry and link back when appropriate.

## Active Agents

| Name | Slug | Purpose | Version | Authority | Runtime | System Of Record | Lifecycle | Operator | Created | Last Verified | Verification Isolation | Last Kill Test | Manifest | Spec | Verify | Kill Switch | Runtime Evidence | Status |
|------|------|---------|---------|-----------|---------|------------------|-----------|----------|---------|---------------|------------------------|----------------|----------|------|--------|-------------|------------------|--------|

## Experimental Agents

| Name | Slug | Purpose | Version | Authority | Runtime | System Of Record | Lifecycle | Operator | Created | Last Verified | Verification Isolation | Last Kill Test | Manifest | Spec | Verify | Kill Switch | Runtime Evidence | Status |
|------|------|---------|---------|-----------|---------|------------------|-----------|----------|---------|---------------|------------------------|----------------|----------|------|--------|-------------|------------------|--------|

## Paused Agents

| Name | Slug | Purpose | Version | Authority | Runtime | System Of Record | Lifecycle | Operator | Created | Paused Reason | Manifest | Spec | Verify | Kill Switch | Runtime Evidence | Status |
|------|------|---------|---------|-----------|---------|------------------|-----------|----------|---------|---------------|----------|------|--------|-------------|------------------|--------|

## Deprecated Agents

| Name | Slug | Purpose | Version | Authority | Runtime | System Of Record | Lifecycle | Operator | Created | Deprecated Reason | Manifest | Spec | Verify | Kill Switch | Runtime Evidence | Status |
|------|------|---------|---------|-----------|---------|------------------|-----------|----------|---------|-------------------|----------|------|--------|-------------|------------------|--------|

## Change Log

| Date | Operator | Change | Evidence |
|------|----------|--------|----------|
| 2026-04-29 | Fer Miras / waitdeadai | Initialized Hermes registry schema for `/agentfactory`. | `.claude/skills/agentfactory/SKILL.md`, `SPEC.md` |
| 2026-04-29 | Fer Miras / waitdeadai | Added runtime, verification, kill-switch, isolation, and runtime-evidence columns for enterprise readiness. | `.claude/skills/agentfactory/SKILL.md`, `scripts/agentfactory-smoke.sh`, `SPEC.md` |
