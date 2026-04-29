# SPEC: AgentFactory Runtime Contract Hardening

## Problem Statement
`/agentfactory` is now a first-class workflow for creating Hermes agents, but the current contract can still produce agents that look governed in Markdown without proving runtime compatibility. REVCLI makes the missing layer concrete: generated Hermes agents must bind to a control plane, system of record, approvals, audit sink, kill switch, and argument-level capability constraints before they can claim enterprise readiness.

Harden `/agentfactory` so generated Hermes agents are reproducible, REVCLI-ready, and falsifiable by executable evidence rather than prose.

## Codebase Anchors
- `.claude/skills/agentfactory/SKILL.md` owns the Agent Factory phase contract, schemas, generated file formats, and hard gates.
- `scripts/agentfactory-smoke.sh` owns static and fixture-level regression checks for Agent Factory invariants.
- `scripts/test-harness.sh` calls the Agent Factory smoke test as part of the repo harness.
- `hermes-registry.md` is the root source of truth for generated Hermes agent status.
- `hermes-factory.taste.md` defines the secondary taste contract for safe agent creation.
- `AGENT_FACTORY_AUDIT_AND_BLUEPRINT.md` records the research/audit/design ledger.
- `README.md`, `CLAUDE.md`, and `AGENTS.md` are operator-facing contracts.
- `/home/fer/Music/REVCLI/revcli/headless-pilot/` is the local REVCLI runtime-control-plane evidence surface.
- `/home/fer/Music/REVCLI/apps/revis-saas/` is the local Revis SaaS runtime/audit/approval evidence surface.

## Success Criteria
- [ ] `/agentfactory` requires a machine-readable `hermes.runtime.json` file for every generated Hermes agent.
- [ ] `hermes.runtime.json` includes entrypoint, cwd, args schema, argv allowlist, env allowlist, config path allowlist, input limits, allowed and denied actions, approval gates, audit sink, kill switch, fixtures, and expected statuses.
- [ ] `hermes.manifest.md` and the manifest schema include parseable runtime-control-plane, system-of-record, action-authority, credential, egress, observability, and status-transition contracts.
- [ ] `/agentfactory` includes a REVCLI readiness overlay requiring role-scoped profile, REVCLI/Revis policy authority, Odoo/DB system-of-record correlation, auth mode, approval gate map, egress allowlist, audit trace, kill-switch compatibility, closed-loop terminal state, and no unmanaged execution channel.
- [ ] `hermes.verify.md` requires executable test rows with command, fixture, expected result, actual result, evidence path, verifier, and status.
- [ ] `hermes.kill-switch.md` requires a runtime-backed test command, expected exit code/status, expected audit event, evidence path, last tested timestamp, and result.
- [ ] `hermes-registry.md` includes verification, kill-switch, runtime evidence, verification isolation, and last kill test columns for active and experimental agents.
- [ ] Active status is illegal unless verification is `verified`, registry evidence links are present, kill-switch evidence passed, and no unresolved production-risk residual remains.
- [ ] Legacy verification waiver language is replaced with an explicit `operator_exception` state that cannot be active and cannot hold read-write or destructive authority.
- [ ] `scripts/agentfactory-smoke.sh` checks the new runtime contract terms, registry evidence columns, active-row invariants, and negative fixture cases.
- [ ] `REVCLI_HERMES_AGENT_MAP.md` exists and maps REVCLI product/workflow surfaces to candidate Hermes agents, risks, approvals, runtime evidence, and priority.
- [ ] README/CLAUDE/AGENTS explain that `/agentfactory` generates runtime-bound Hermes agents, not merely prompt/document bundles.
- [ ] Verification commands pass or any blocker is reported with concrete evidence.

## Scope
### In Scope
- Strengthen the Agent Factory skill contract and generated file specs.
- Add a REVCLI enterprise runtime overlay and agent portfolio map.
- Upgrade registry schema and smoke tests so readiness claims are falsifiable.
- Update operator documentation and active spec.

### Out of Scope
- Editing the private REVCLI repository in this change.
- Generating a concrete Hermes agent directory under `.taste/hermes-agents/`.
- Building the actual REVCLI MCP/API bridge or runtime wrappers.
- Deploying Revis SaaS or provisioning external credentials.

## Surgical Diff Discipline
- Smallest sufficient implementation: update Agent Factory contracts, docs, tests, and the REVCLI map only.
- No speculative runtime engine: require `hermes.runtime.json` and executable evidence, but do not invent a new orchestrator.
- No drive-by REVCLI edits: use REVCLI as read-only evidence.
- Changed-line trace: every meaningful edit maps to a success criterion above.

## Implementation Plan
1. Update `.claude/skills/agentfactory/SKILL.md` with runtime-control-plane gates, REVCLI overlay, `hermes.runtime.json`, stricter manifest/verify/kill-switch formats, transition matrix, and registry schema.
2. Update `hermes-registry.md` with evidence columns.
3. Add `REVCLI_HERMES_AGENT_MAP.md` from local REVCLI audit evidence.
4. Update `scripts/agentfactory-smoke.sh` with required runtime contract terms, registry column assertions, active row checks, and negative fixtures.
5. Update `scripts/test-harness.sh`, README, CLAUDE, AGENTS, and the audit blueprint to reflect enterprise runtime readiness.
6. Run shell syntax, Agent Factory smoke, full harness, diff checks, and targeted grep checks for stale contracts.

## Verification
- `bash -n scripts/agentfactory-smoke.sh`
- `bash scripts/agentfactory-smoke.sh`
- `bash -n scripts/test-harness.sh`
- `bash -n scripts/start-session.sh`
- `bash scripts/test-harness.sh`
- `git diff --check`
- targeted stale command-name grep over changed docs and scripts
- `rg "hermes.runtime.json|Runtime Control Plane|REVCLI Readiness Overlay|operator_exception" .claude/skills/agentfactory/SKILL.md scripts/agentfactory-smoke.sh hermes-registry.md README.md`

## Rollback Plan
- Revert the Agent Factory skill, smoke script, registry, docs, and REVCLI map changes.
- Restore the prior Agent Factory contract from git history if the stricter runtime contract proves too heavy.
- Leave archived specs untouched.
