# Hermes Factory Taste

version: 1

## Principles
- Hermes agents are governed operating units, not generic prompts.
- Bounded authority beats broad autonomy.
- Every capability grant must be justified, auditable, testable, and killable.
- Enterprise-scale Hermes systems should be composed from narrow agents with explicit handoffs instead of one omnipotent agent.
- Runtime control planes own authorization, approval, audit, and system-of-record writes when they already exist.

## Enterprise Operating Model
- A Hermes agent may operate one workflow, one role lane, one department function, or one bounded subsystem.
- A Hermes fleet may operate a larger business process only when each agent has a manifest, registry entry, scope boundary, escalation trigger, verification contract, and kill switch.
- Supervisory or coordinator agents route work; they do not silently inherit every child agent permission.
- Human accountability remains explicit even when execution is automated.

## Approval Philosophy
- Read-only research and classification can be autonomous when scope and data access are explicit.
- Internal read-write actions can be autonomous only through governed runtime actions with audit logs and rollback semantics.
- Destructive, customer-visible, financial, legal, credential, hiring, compliance, or external-send actions require explicit approval unless a policy-bound manifest proves otherwise and verification tests it.

## Memory Philosophy
- Memory is a contract surface, not a scrapbook.
- Semantic, procedural, error-solution, episodic, and causal graph entries must not contradict each other.
- Memory seeds must cite their source and state whether they supersede or contradict older entries.
- Unresolved contradiction blocks production readiness.

## Non-Goals
- No omnipotent enterprise agent.
- No hidden credentials or raw secrets in manifests, prompts, memory seeds, or deployment docs.
- No direct system-of-record writes when a governed runtime action exists.
- No production-ready status without independent verification and a tested kill switch.
- No registry drift between what exists on disk and what operators believe is running.
