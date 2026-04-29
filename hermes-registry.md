# Hermes Registry

## Registry Contract
- Source of truth for Hermes agents created by `/agentfactory`.
- Status values: `active`, `deprecated`, `experimental`, `paused`.
- Every active agent must link to manifest, spec, verification, and kill-switch evidence.
- Registry updates require `/agentfactory` or an explicit operator-approved maintenance change.
- The registry tracks agents that exist in this repo; external private consumer repos may keep their own registry and link back when appropriate.

## Active Agents

| Name | Slug | Purpose | Version | Authority | Lifecycle | Operator | Created | Last Verified | Manifest | Spec | Status |
|------|------|---------|---------|-----------|-----------|----------|---------|---------------|----------|------|--------|

## Experimental Agents

| Name | Slug | Purpose | Version | Authority | Lifecycle | Operator | Created | Last Verified | Manifest | Spec | Status |
|------|------|---------|---------|-----------|-----------|----------|---------|---------------|----------|------|--------|

## Paused Agents

| Name | Slug | Purpose | Version | Authority | Lifecycle | Operator | Created | Paused Reason | Manifest | Spec | Status |
|------|------|---------|---------|-----------|-----------|----------|---------|---------------|----------|------|--------|

## Deprecated Agents

| Name | Slug | Purpose | Version | Authority | Lifecycle | Operator | Created | Deprecated Reason | Manifest | Spec | Status |
|------|------|---------|---------|-----------|-----------|----------|---------|-------------------|----------|------|--------|

## Change Log

| Date | Operator | Change | Evidence |
|------|----------|--------|----------|
| 2026-04-29 | Fer Miras / waitdeadai | Initialized Hermes registry schema for `/agentfactory`. | `.claude/skills/agentfactory/SKILL.md`, `SPEC.md` |
