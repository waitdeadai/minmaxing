# Agent Factory Audit And Blueprint

Generated: 2026-04-29

Scope: `minmaxing` in `/home/fer/Music/ultimateminimax` and local private `REVCLI` in `/home/fer/Music/REVCLI`.

## AUDIT: minmaxing

| Question | Finding | Evidence | Decision |
|----------|---------|----------|----------|
| Does `/workflow` trust agent output without verification? | For file-changing work, no. `/workflow` requires deep research, audit, plan, `SPEC.md`, execution, post-implementation introspection, verification, and closeout evidence. Analysis-only routes can report directly without `SPEC.md`; that is a deliberate non-implementation path, not trusted code output. | `.claude/skills/workflow/SKILL.md` lines 20-30, 37-55, 459-504. | Keep `/agentfactory` verification mandatory before active status. |
| Are there hidden skill dependencies? | Yes, for direct specialist invocation. `/verify` assumes `SPEC.md`; `/sprint` assumes owned tasks; `/autoplan` assumes taste and memory; `/workflow` avoids nested chaining and owns the lifecycle inline. | `.claude/skills/workflow/SKILL.md` lines 29-35 and 540-548; `.claude/skills/verify/SKILL.md` lines 29-36. | `/agentfactory` must be self-contained and not depend on nested skill continuation. |
| Can memory produce contradictory entries across tiers? | Yes. `scripts/memory.sh` writes flat files first and SQLite best-effort; SQLite sync can fail while flat files remain. There is no cross-tier contradiction checker. Error-solution parsing is fragile because it cuts quoted strings by delimiter. | `scripts/memory.sh` lines 61-74, 91-111, 175-183, 207-247. | `/agentfactory` requires memory seed contradiction checks and explicit supersedes/contradicts fields. |
| Is `CURRENT.md` compaction-safe in all failure modes? | It is compaction-safe for normal hook paths, but not crash-proof. Stop, precompact, postcompact, snapshot, and session-start hydrate are covered; hard kills, power loss, hook failure, or out-of-band edits can leave stale state. | `scripts/state.sh` lines 201-234, 244-286, 307-341, 373-376; `CLAUDE.md` lines 122-135. | Treat `CURRENT.md` as a hint and pair it with workflow artifacts and live `git status`. |
| Does `/introspect` have a bypass path? | In `/workflow` file-changing runs, it is a hard gate. Bypass exists only if an operator invokes specialist skills directly or edits outside `/workflow`. | `.claude/skills/workflow/SKILL.md` lines 24-27, 326-347, 442-455; `.claude/skills/introspect/SKILL.md` lines 15-42. | `/agentfactory` embeds Phase 6.5 introspection inline. |
| Is there escalation when `/verify` fails? | Yes. `/workflow` requires after-test-failure introspection, identifies whether fix, plan, spec, or test is wrong, fixes, and re-verifies until accepted or blocked. `/verify` also instructs logging rejected criteria. | `.claude/skills/workflow/SKILL.md` lines 469-475; `.claude/skills/verify/SKILL.md` lines 110-142. | Hermes verification failure prevents `active` status. |
| Is surgical diff discipline enforced? | Enforced by skill contracts and static harness tests, not by an AST-level diff parser. It can still be bypassed outside the harness. | `.claude/skills/workflow/SKILL.md` lines 27 and 486-502; `scripts/test-harness.sh` lines 290-299. | `/agentfactory` adds static harness coverage for its own invariants. |
| Are 20 skills truly independent? | No. They are better understood as callable playbooks sharing repo truth surfaces. The system-call metaphor is useful, but several skills assume upstream artifacts. The repo now has 21 skills after `/agentfactory`. | `README.md` lines 451-475; `CLAUDE.md` lines 37-68. | Document `/agentfactory` as first-class while keeping `/workflow` as shell. |

## AUDIT: revcli

| Question | Finding | Evidence | Agent Factory Implication |
|----------|---------|----------|---------------------------|
| Natural Hermes extension points | REVCLI already exposes workflow specs, shared state files, bundle shortcuts, headless pilot domain service, Hermes profiles, runtime audit hooks, and guided Revis runtime APIs. | `revcli/README.md` lines 1-21, 48-84, 97-108; `integrations/hermes/README.md` lines 1-11 and 125-155. | Hermes agents should plug into REVCLI as governed workflow callers, not direct CRM actors. |
| Authentication and credentials | Odoo bridge uses bearer token from env, ingest script expects `REVCLI_ODOO_API_TOKEN`, Hermes provider docs require env/secret managers, and profile auth distinguishes seat-attached from fleet-commercial. | `revcli/headless-pilot/adapters/odoo-adapter.mjs` lines 3-20 and 151-200; `scripts/ingest-nurture-trigger.mjs` lines 18-35; `integrations/hermes/README.md` lines 63-86. | Hermes manifests must deny raw secrets and document env vars only. Autonomous agents should use fleet-commercial or runtime-owned tokens, not hidden consumer seat OAuth. |
| Best repetitive low-judgment task | Nurture signal ingestion and re-entry monitoring is the best first Hermes candidate: sources are normalized, opportunity resolution exists, routing decisions are bounded, and first-touch sending remains human-reviewed. | `revcli/headless-pilot/README.md` lines 84-99; `nurture-trigger-connectors.mjs` lines 1-94 and 138-194; `autonomy-policy.mjs` lines 23-58 and 60-90. | First blueprint is `revcli-nurture-signal-monitor`. |
| Irreversible action risk | External sends, owner changes, close-won/close-lost, proposal, discount, contract, legal, and sensitive deletes would break business trust if automated without approval. | `schemas.mjs` lines 52-92; `autonomy-policy.mjs` lines 36-58 and 252-270; `workflow-authorization-policy.mjs` lines 42-144. | The first agent must deny external send, approval, closure, owner change, proposal, discount, and contract actions. |
| Memory/state maintained | REVCLI maintains `.beads` workflow state, workflow I/O contracts, `context_json` operational state, audit JSONL/hash chain, and CRM/Odoo bridge records. | `revcli/README.md` lines 67-84; `domain-service.mjs` lines 37-110 and 184-300; `runtime-audit.mjs` lines 37-95 and 152-205. | Hermes memory seed should reference REVCLI decisions but not duplicate system-of-record state. |
| Existing authorization model | REVCLI has action-level roles, team scopes, owner/delegate checks, distinct-principal rules, and deny-closed safeguards. | `workflow-authorization-policy.mjs` lines 42-144 and 262-330. | Hermes must call authorized REVCLI actions and include authorization denial as an escalation trigger. |
| Existing audit model | Hermes hook payloads are normalized, redacted, hashed, and written to JSONL or API. | `integrations/hermes/hooks/revcli_audit_sink.mjs` lines 1-72; `runtime-audit.mjs` lines 25-28, 37-95, and 186-205. | Audit sink is a required capability for production Hermes agents. |

## AGENT FACTORY: Skill Specification

Installed as `.claude/skills/agentfactory/SKILL.md`.

| Phase | Name | Gate | Required Output |
|-------|------|------|-----------------|
| 0 | Taste Gate | Purpose must align with `taste.md`, `taste.vision`, and `hermes-factory.taste.md`. | Taste decision: `PASS`, `NEEDS_ALIGNMENT`, or `BLOCKED`. |
| 1 | Hermes Intent Intake | 12 kernel questions must be answered; no implicit tools. | Complete intent contract. |
| 2 | Deep Research | Runtime/auth/destructive/system-of-record ambiguity blocks. | Source ledger, repo evidence, failure modes, best practices, contradictions. |
| 3 | Hermes Manifest Drafting | Required fields cannot be missing, vague, contradictory, or secret-bearing. | `hermes.manifest.md` draft. |
| 4 | Capability Stack Design | Any capability without use-case justification is removed. | Least-privilege stack, MCP scopes, memory seed plan, prompt construction rules. |
| 5 | Hermes `SPEC.md` | Spec must exist before generated files. | `.taste/hermes-agents/{slug}/HERMES-{SLUG}-SPEC.md`. |
| 6 | Agent File Generation | All required files must be generated under one agent directory. | Manifest, prompt, taste, memory seed, runtime contract, deploy, verify, kill-switch, spec. |
| 6.5 | Introspect | Tool justification, escalation coverage, objective criterion, kill switch, authority match, memory coherence, runtime bypass check. | `PASS`, `FIX_REQUIRED`, `REPLAN_REQUIRED`, or `BLOCKED`. |
| 7 | Independent Verification | Failure prevents `active`; verifier metadata required. | Smoke, boundary, memory, escalation, capability, kill-switch, audit tests. |
| 8 | Closeout And Registry | No `active` registry row without kill-switch test and verification metadata. | Agent directory, registry row, semantic memory log, spec archive, state update. |

The 12 kernel questions are in `.claude/skills/agentfactory/SKILL.md` lines 63-84 and must be asked verbatim.

## HERMES MANIFEST SCHEMA

| Field | Required | Type | Valid Values | Invalid When |
|-------|----------|------|--------------|--------------|
| `manifest_version` | yes | string | semantic version, default `1.0` | missing, empty, non-string |
| `name` | yes | string | 3-80 char human name | vague, duplicate, includes secret |
| `slug` | yes | string | lowercase kebab-case | not unique, not kebab-case |
| `version` | yes | string | semver | not semver |
| `status` | yes | enum | `experimental`, `active`, `paused`, `deprecated` | other value |
| `created_at` | yes | string | `YYYY-MM-DD` | invalid date |
| `operator` | yes | string | creator | missing |
| `accountability_owner` | yes | string | accountable human | missing |
| `purpose` | yes | string | one sentence | vague, multi-sentence |
| `scope_boundary` | yes | list[string] | explicit never-do items | empty |
| `non_goals` | yes | list[string] | excluded outcomes | empty |
| `decision_authority` | yes | enum | `read-only`, `read-write`, `destructive-allowed` | mismatches grants |
| `target_runtime` | yes | string | named runtime | missing |
| `runtime_control_plane` | yes | object | name, owner, policy authority, invocation surface, state store, audit sink | missing authority or audit sink |
| `system_of_record` | yes | object | name, write policy, adapter/API, direct-write flag | direct write allowed without approval proof |
| `runtime_identity` | yes | object | principal, auth mode, tenant scope, revocation path | shared hidden credentials |
| `deployment_lifecycle` | yes | enum | `ephemeral`, `persistent`, `scheduled` | other value |
| `capability_stack` | yes | list[object] | `type`, `name`, `scope`, `justification`, `risk`, `approval_required` | grant lacks justification |
| `mcp_servers` | yes | list[object] | `name`, `transport`, `scopes`, `justification`, `approval_model` | broad scope |
| `api_access` | yes | list[object] | `service`, `env_vars`, `allowed_methods`, `denied_methods`, `justification` | includes secret values |
| `file_access` | yes | list[object] | `path`, `mode`, `purpose` | write without reason |
| `workflow_access` | yes | list[object] | `workflow`, `allowed_actions`, `denied_actions`, `approval_required` | unapproved side effect |
| `action_authority_matrix` | yes | list[object] | action, side-effect level, runtime action, approval gate, rollback/compensation, idempotency, audit event | side effect lacks approval/audit |
| `credential_strategy` | yes | object | env names, vault/provider, scope, expiry, rotation, revocation, redaction | raw secret value |
| `egress_policy` | yes | object | default deny, allowed/denied domains, proxy/filter, SSRF controls | production allow-all |
| `durable_orchestration` | yes | object | workflow ID, state store, retry, timeout, resume, idempotency | scheduled/persistent without durable state |
| `observability_contract` | yes | object | trace ID, events, sink, redaction, retention, evidence path | no action attribution |
| `memory_seed` | yes | list[object] | `tier`, `id`, `content`, `source`, `contradiction_check` | unresolved contradiction |
| `success_criteria` | yes | list[string] | one objective machine-checkable criterion minimum | all human judgment |
| `escalation_triggers` | yes | list[string] | concrete stop conditions | failure modes uncovered |
| `kill_switch` | yes | object | `mechanism`, `owner`, `test_command`, `last_tested`, `expected_result` | untested for active |
| `audit_logging` | yes | object | `events`, `sink`, `redaction`, `retention` | no outcome logging |
| `handoff_protocol` | yes | object | `when`, `to_whom`, `payload`, `timeout` | missing owner/payload |
| `verification_status` | yes | enum | `draft`, `verified`, `failed`, `operator_exception` | verified without evidence; operator exception with active/read-write/destructive authority |
| `constraints` | yes | list[string] | C1-C12 references | empty |
| `source_ledger` | yes | list[object] | repo/memory/external sources | missing for non-trivial design |

Optional fields: `parent_agent`, `child_agents`, `schedule`, `rollback_plan`, `cost_budget`, `data_classification`.

## FILE FORMAT SPECIFICATIONS

### `hermes.manifest.md`

```markdown
---
manifest_version: "1.0"
name: "{Name}"
slug: "{slug}"
version: "0.1.0"
status: "experimental"
created_at: "YYYY-MM-DD"
operator: "{operator}"
accountability_owner: "{owner}"
purpose: "{one sentence}"
decision_authority: "read-only|read-write|destructive-allowed"
target_runtime: "{runtime}"
runtime_control_plane:
  name: "{runtime control plane}"
  owner: "{runtime owner}"
  policy_authority: "{policy authority}"
  invocation_surface: "{cli|api|mcp|workflow|sandbox}"
  state_store: "{state store}"
  audit_sink: "{audit sink}"
system_of_record:
  name: "{system of record}"
  write_policy: "{runtime-mediated|read-only|direct-with-approval}"
  adapter_or_api: "{adapter or API}"
  direct_write_allowed: false
runtime_identity:
  principal: "{agent principal}"
  auth_mode: "seat-attached|fleet-commercial|local-dev"
  tenant_scope: "{tenant/team/scope}"
  revocation_path: "{how identity is revoked}"
action_authority_matrix: []
credential_strategy:
  env_var_names: []
  vault_or_provider: "{vault/provider/runtime-injected}"
  scope: "{credential scope}"
  expiry: "{expiry policy}"
  rotation: "{rotation policy}"
  revocation: "{revocation path}"
  redaction: "{redaction policy}"
egress_policy:
  default: "deny"
  allowed_domains: []
  denied_domains: []
  proxy_or_filter: "{proxy/filter}"
  ssrf_controls: []
durable_orchestration:
  workflow_id: "{workflow id}"
  state_store: "{state store}"
  retry_policy: "{retry policy}"
  timeout_policy: "{timeout policy}"
  resume_policy: "{resume policy}"
  idempotency: "{idempotency policy}"
observability_contract:
  trace_id: "{trace id field}"
  events: []
  sink: "{audit/trace sink}"
  redaction: "{redaction policy}"
  retention: "{retention policy}"
  evidence_path: "{evidence path}"
deployment_lifecycle: "ephemeral|persistent|scheduled"
verification_status: "draft"
---

# Hermes Manifest: {Name}

## Purpose
## Scope Boundary
## Non-Goals
## Capability Stack
## MCP Servers
## API Access
## File Access
## Workflow Access
## Action Authority Matrix
## Credential Strategy
## Egress Policy
## Durable Orchestration
## Observability Contract
## Memory Seed Summary
## Success Criteria
## Escalation Triggers
## Kill Switch
## Audit Logging
## Handoff Protocol
## Source Ledger
## Constraint Trace
```

### `hermes.system-prompt.md`

```markdown
# System Prompt: {Name}

## Identity
## Mission
## Authority
## Operating Rules
## Tool Policy
## Memory Policy
## Runtime Policy
## Escalation Policy
## Refusal Policy
## Output Contract
## Audit Logging Requirements
```

### `hermes.taste.md`

```markdown
---
agent: "{slug}"
version: "0.1.0"
---

# Hermes Taste: {Name}

## Principles
## Enterprise Operating Model
## Decision Style
## Scope Discipline
## Human Handoff
## Observability
## Non-Goals
```

### `hermes.memory-seed.json`

```json
{
  "schema_version": "1.0",
  "agent_slug": "{slug}",
  "generated_at": "YYYY-MM-DD",
  "contradiction_check": {
    "status": "pass",
    "method": "semantic/procedural/error-solution/episodic/causal graph cross-check",
    "notes": []
  },
  "entries": []
}
```

### `hermes.runtime.json`

```json
{
  "schema_version": "1.0",
  "agent_slug": "revcli-nurture-signal-monitor",
  "runtime_control_plane": {
    "name": "REVCLI headless pilot",
    "policy_authority": "revcli/headless-pilot/workflow-authorization-policy.mjs",
    "state_store": "REVCLI workflow run and Odoo adapter state",
    "audit_sink": "integrations/hermes/hooks/revcli_audit_sink.mjs",
    "system_of_record": "Odoo/CRM via REVCLI adapter"
  },
  "identity": {
    "principal": "revcli-nurture-signal-monitor",
    "auth_mode": "fleet-commercial",
    "tenant_scope": "REVCLI headless pilot",
    "credential_source": "env|vault|runtime-injected",
    "env_var_names": [
      "REVCLI_HEADLESS_CONFIG",
      "REVCLI_ODOO_API_TOKEN",
      "REVIS_AUDIT_LOG",
      "REVIS_AUDIT_API_URL",
      "REVIS_AUDIT_API_TOKEN",
      "HERMES_REVCLI_NURTURE_MONITOR_ENABLED"
    ],
    "revocation_path": "disable schedule/profile and revoke runtime token"
  },
  "entrypoint": {
    "type": "cli",
    "command": "node scripts/ingest-nurture-trigger.mjs",
    "cwd": "/home/fer/Music/REVCLI",
    "argv_allowlist": ["--config", "revcli/headless-pilot/config.json", "--input"],
    "denied_flags": ["--send", "--approve", "--close", "--owner", "--token"],
    "allowed_config_paths": ["revcli/headless-pilot/config.json"],
    "env_allowlist": [
      "REVCLI_HEADLESS_CONFIG",
      "REVCLI_ODOO_API_TOKEN",
      "REVIS_AUDIT_LOG",
      "REVIS_AUDIT_API_URL",
      "REVIS_AUDIT_API_TOKEN",
      "HERMES_REVCLI_NURTURE_MONITOR_ENABLED"
    ],
    "input_schema": ".taste/hermes-agents/revcli-nurture-signal-monitor/fixtures/nurture-event.schema.json",
    "max_input_bytes": 32768
  },
  "actions": {
    "allowed": [
      {
        "name": "process-nurture-trigger",
        "side_effect_level": "internal-write",
        "approval_gate": "none for valid normalized event; human approval before outbound send",
        "idempotency_key": "source_type:event_id:opportunity_id",
        "rollback_or_compensation": "mark queued task skipped and preserve audit event",
        "audit_event": "nurture_event_processed"
      }
    ],
    "denied": ["external-send", "approve-outreach", "close-won", "close-lost", "owner-change", "direct-odoo-write"]
  },
  "egress_policy": {
    "default": "deny",
    "allowed_domains": [],
    "denied_domains": [],
    "ssrf_controls": ["block-private-ip", "validate-redirects"]
  },
  "durable_orchestration": {
    "workflow_id": "revcli-nurture-signal-monitor:{event_id}",
    "state_store": "REVCLI workflow run/audit evidence",
    "retry_policy": "bounded retry with idempotency key",
    "timeout_policy": "operator-defined SLA",
    "resume_policy": "resume same run ID"
  },
  "observability": {
    "trace_id_field": "trace_id",
    "events": ["processed", "skipped", "escalated", "denied", "disabled"],
    "redaction": "secret-key recursive redaction",
    "retention": "REVCLI audit policy",
    "evidence_path": ".taste/hermes-agents/revcli-nurture-signal-monitor/evidence/"
  },
  "kill_switch": {
    "mechanism": "HERMES_REVCLI_NURTURE_MONITOR_ENABLED=false plus schedule/profile/token disable",
    "test_command": "HERMES_REVCLI_NURTURE_MONITOR_ENABLED=false node scripts/ingest-nurture-trigger.mjs --config revcli/headless-pilot/config.json --input fixtures/valid-website-return.json",
    "expected_exit_code": 0,
    "expected_status": "disabled",
    "expected_audit_event": "nurture_monitor_disabled",
    "evidence_path": ".taste/hermes-agents/revcli-nurture-signal-monitor/evidence/kill-switch.json"
  },
  "fixtures": [
    {
      "name": "valid-website-return",
      "path": "fixtures/valid-website-return.json",
      "expected_status": "processed|escalated",
      "expected_audit_event": "nurture_event_processed"
    }
  ],
  "expected_statuses": ["processed", "skipped", "escalated", "denied", "disabled"]
}
```

### `hermes.deploy.md`

```markdown
# Deploy: {Name}

## Runtime
## Invocation
## Environment Variables
## Authentication
## Authorized Network/API Surface
## Schedule Or Trigger
## Observability
## Rollback
## Operational Runbook
## Production Readiness Checklist
```

### `hermes.verify.md`

```markdown
# Verify: {Name}

## Verification Metadata
## Success Criteria Matrix
## Smoke Test
## Behavioral Boundary Test
## Memory Integrity Check
## Escalation Test
## Capability Authorization Test
## Kill Switch Test
## Audit Log Test
## Result
```

### `hermes.kill-switch.md`

```markdown
# Kill Switch: {Name}

## Owner
## Disable Mechanisms
## Test Procedure
## Expected Result
## Last Test Evidence
## Recovery Procedure
## Failure Escalation
```

### `HERMES-{SLUG}-SPEC.md`

Required sections: Purpose Contract, Taste Alignment, Runtime And Integration Surface, Runtime Contract, Authority Model, Capability Grants, Action Authority Matrix, Memory Seed Contract, Durable Orchestration Contract, Verification Contract, Escalation And Handoff Contract, Kill Switch Contract, Audit And Observability Contract, Security And Credential Contract, Success Criteria, Non-Goals, Failure Modes, Implementation Plan, Independent Verification Plan, Rollback Plan, Constraint Trace.

## HERMES REGISTRY SCHEMA

Root file: `hermes-registry.md`.

Status values: `active`, `deprecated`, `experimental`, `paused`.

Required lookup columns: `Name`, `Slug`, `Purpose`, `Version`, `Authority`, `Runtime`, `System Of Record`, `Lifecycle`, `Operator`, `Created`, `Last Verified` or reason column, `Verification Isolation`, `Last Kill Test`, `Manifest`, `Spec`, `Verify`, `Kill Switch`, `Runtime Evidence`, `Status`.

The initialized registry is in `hermes-registry.md` lines 1-34.

## FIRST HERMES AGENT BLUEPRINT

### Agent Choice

Agent: `revcli-nurture-signal-monitor`.

Why this first: REVCLI already has source normalizers, opportunity resolution, nurture trigger processing, authorization rules, audit sinks, and policy that keeps first-touch sending human-reviewed. The task is high-volume, repetitive, and low-judgment when constrained to signal ingestion, match resolution, review queueing, and audit logging.

### `HERMES-revcli-nurture-signal-monitor-SPEC.md`

```markdown
# HERMES SPEC: REVCLI Nurture Signal Monitor

## Purpose Contract
Monitor normalized nurture-source events, resolve the matching REVCLI opportunity, create an internal signal, and route eligible accounts into governed nurture or outreach review without sending external messages.

## Taste Alignment
Aligned with minmaxing taste-first governance and `hermes-factory.taste.md`: bounded workflow ownership, no hidden credentials, no direct system-of-record bypass, auditability, memory coherence, and tested kill switch.

## Runtime And Integration Surface
Target runtime: local/private REVCLI runtime in `/home/fer/Music/REVCLI`.
Invocation: `node scripts/ingest-nurture-trigger.mjs --config revcli/headless-pilot/config.json --input <event.json>` or stdin JSON.
Primary REVCLI modules: `scripts/ingest-nurture-trigger.mjs`, `revcli/headless-pilot/nurture-trigger-connectors.mjs`, `revcli/headless-pilot/domain-service.mjs`, `revcli/headless-pilot/workflow-authorization-policy.mjs`, `integrations/hermes/hooks/revcli_audit_sink.mjs`.

## Runtime Contract
Required runtime artifact: `.taste/hermes-agents/revcli-nurture-signal-monitor/hermes.runtime.json`.
The runtime contract must pin cwd, command, allowed config path, env allowlist, input schema, max input bytes, allowed/denied runtime actions, approval gates, audit sink, kill switch, fixtures, and expected statuses.

## Authority Model
Decision authority: read-write, internal-only.
Allowed writes: internal signal records, workflow runs, review tasks, audit events through REVCLI-governed actions.
Denied writes: external messages, outreach approval, close-won, close-lost, owner reassignment, proposal, discount, contract, raw CRM mutation outside REVCLI service.

## Capability Grants
Grant 1: Shell execution of exact REVCLI ingest command.
Grant 2: Read access to REVCLI workflow/config/profile docs.
Grant 3: Environment-variable access by name only: `REVCLI_HEADLESS_CONFIG`, `REVCLI_ODOO_API_TOKEN`, `REVIS_AUDIT_LOG`, `REVIS_AUDIT_API_URL`, `REVIS_AUDIT_API_TOKEN`, `HERMES_REVCLI_NURTURE_MONITOR_ENABLED`.
Grant 4: Audit sink invocation.

## Action Authority Matrix
Allowed actions: process normalized nurture trigger, create internal signal, queue outreach/nurture review, log audit event.
Denied actions: external send, direct Odoo write, proposal send, close won/lost, owner reassignment, pricing/redline, credential export.
Every allowed internal write requires a REVCLI runtime action, idempotency key, and audit event.

## Memory Seed Contract
Semantic: first-touch sending always requires human review.
Procedural: use `scripts/ingest-nurture-trigger.mjs`; do not call Odoo directly.
Error-solution: no opportunity match and ambiguous match escalate instead of guessing.
Causal graph: nurture signal quality improves seller review focus when matched to active nurture/opportunity context.

## Durable Orchestration Contract
Scheduled runs must carry a workflow/run ID, idempotency key, retry policy, timeout policy, and resume policy. Delayed approval or audit-sink failure must preserve state and not start a new uncorrelated run.

## Verification Contract
Smoke test: synthetic event against mock adapter or dry-run harness returns scoped processed/no-op result.
Boundary test: request to send email is refused and logged as denied.
Memory check: seed entries contain no contradiction.
Escalation test: ambiguous/no-opportunity match produces human handoff payload.
Kill switch test: disabled env/schedule prevents new processing.

## Escalation And Handoff Contract
Escalate on no opportunity match, multiple equal-confidence opportunities, missing token/config, authorization denial, source type unsupported, legal/privacy/high-risk flag, external send request, approval/closure/owner change request, audit sink failure.

## Kill Switch Contract
Mechanisms: set `HERMES_REVCLI_NURTURE_MONITOR_ENABLED=false`; disable schedule/trigger; suspend Hermes profile via founder auditor; revoke runtime token.
Production-ready only after test evidence proves new events are not processed while disabled.

## Audit And Observability Contract
Every event processed, skipped, escalated, or denied is written to REVCLI audit sink with secret redaction and trace/run identifiers.

## Security And Credential Contract
No raw tokens in files. Secrets only via env/secret manager. No Claude.ai consumer session as autonomous backend.

## Success Criteria
- Synthetic website-return event produces either `processed` with audit evidence or `no-opportunity-match` handoff.
- Boundary test refuses external send.
- Kill switch test blocks processing.
- Audit event contains no raw secret-shaped fields.
- Manifest has no capability without justification.

## Non-Goals
No external outreach send.
No self-approval.
No opportunity closure.
No owner change.
No direct Odoo writes outside REVCLI adapter/domain service.

## Failure Modes
Permission creep, runtime bypass, no match guessed, ambiguous match guessed, audit sink failure, token leakage, unkillable schedule, memory contradiction, registry drift, verification theater.

## Implementation Plan
Create Hermes files under `.taste/hermes-agents/revcli-nurture-signal-monitor/`.
Run smoke, boundary, escalation, audit, and kill-switch tests.
Register as `experimental` until real runtime credentials and separate verification are proven.

## Independent Verification Plan
Verifier reads this spec and all Hermes files, then runs dry-run/mock tests without relying on executor claims.

## Rollback Plan
Disable env flag, remove schedule, suspend profile, revoke token, mark registry status `paused`, preserve audit logs.

## Constraint Trace
C1 reproducible, C2 auditable, C3 malleable, C4 least privilege, C5 killable, C6 memory-coherent, C7 taste-aligned, C8 compaction-safe, C9 failure-cataloged, C10 zero-trust verification, C11 runtime-bound, C12 side-effect-safe.
```

### `hermes.manifest.md`

```markdown
---
manifest_version: "1.0"
name: "REVCLI Nurture Signal Monitor"
slug: "revcli-nurture-signal-monitor"
version: "0.1.0"
status: "experimental"
created_at: "2026-04-29"
operator: "Fer Miras / waitdeadai"
accountability_owner: "Fer Miras / waitdeadai"
purpose: "Monitor normalized nurture-source events and route eligible REVCLI opportunities into governed review without sending external messages."
decision_authority: "read-write"
target_runtime: "REVCLI local/private headless pilot"
runtime_control_plane:
  name: "REVCLI headless pilot"
  owner: "Fer Miras / waitdeadai"
  policy_authority: "workflow-authorization-policy.mjs"
  invocation_surface: "cli"
  state_store: "REVCLI/Odoo adapter state"
  audit_sink: "integrations/hermes/hooks/revcli_audit_sink.mjs"
system_of_record:
  name: "Odoo/CRM via REVCLI adapter"
  write_policy: "runtime-mediated"
  adapter_or_api: "revcli/headless-pilot/crm-adapter.mjs"
  direct_write_allowed: false
runtime_identity:
  principal: "revcli-nurture-signal-monitor"
  auth_mode: "fleet-commercial"
  tenant_scope: "REVCLI headless pilot"
  revocation_path: "disable schedule/profile and revoke runtime token"
action_authority_matrix: []
credential_strategy:
  env_var_names: ["REVCLI_HEADLESS_CONFIG", "REVCLI_ODOO_API_TOKEN", "REVIS_AUDIT_LOG", "REVIS_AUDIT_API_URL", "REVIS_AUDIT_API_TOKEN", "HERMES_REVCLI_NURTURE_MONITOR_ENABLED"]
  vault_or_provider: "runtime-injected env or secret manager"
  scope: "nurture signal processing only"
  expiry: "operator-defined"
  rotation: "operator-defined"
  revocation: "revoke token and suspend profile"
  redaction: "secret-key recursive redaction"
egress_policy:
  default: "deny"
  allowed_domains: []
  denied_domains: []
  proxy_or_filter: "REVCLI/Revis runtime egress policy"
  ssrf_controls: ["block-private-ip", "validate-redirects"]
durable_orchestration:
  workflow_id: "revcli-nurture-signal-monitor:{event_id}"
  state_store: "REVCLI workflow run/audit evidence"
  retry_policy: "bounded retry with idempotency key"
  timeout_policy: "operator-defined SLA"
  resume_policy: "resume same workflow/run ID"
  idempotency: "event source + event ID + opportunity ID"
observability_contract:
  trace_id: "trace_id"
  events: ["processed", "skipped", "escalated", "denied", "disabled"]
  sink: "REVCLI audit sink"
  redaction: "secret-key recursive redaction"
  retention: "REVCLI audit policy"
  evidence_path: ".taste/hermes-agents/revcli-nurture-signal-monitor/evidence/"
deployment_lifecycle: "scheduled"
verification_status: "draft"
---

# Hermes Manifest: REVCLI Nurture Signal Monitor

## Purpose
Monitor normalized nurture-source events and route eligible REVCLI opportunities into governed review without sending external messages.

## Scope Boundary
- NEVER send external outreach.
- NEVER approve outreach.
- NEVER close opportunities.
- NEVER change owner or team scope.
- NEVER write directly to Odoo outside REVCLI governed actions.
- NEVER expose raw credentials.

## Non-Goals
- Prospect discovery.
- Proposal generation.
- Pricing, legal, contract, or commercial approval.
- Autonomous sales conversation.

## Capability Stack
| Type | Name | Scope | Justification | Risk | Approval Required |
|------|------|-------|---------------|------|-------------------|
| shell | `node scripts/ingest-nurture-trigger.mjs` | exact command only | Ingest normalized source event through REVCLI domain service. | bad input creates noisy review task | no for valid normalized event |
| file-read | REVCLI workflow/config/profile files | read-only | Verify runtime policy and allowed workflows. | stale local dirty snapshot | no |
| audit | `integrations/hermes/hooks/revcli_audit_sink.mjs` | write event | Required operational trace. | audit API/token unavailable | escalate on failure |

## MCP Servers
| Name | Transport | Scopes | Justification | Approval Model |
|------|-----------|--------|---------------|----------------|
| none | none | none | Initial agent uses local REVCLI CLI/actions only. | not applicable |

## API Access
| Service | Env Vars | Allowed Methods | Denied Methods | Justification |
|---------|----------|-----------------|----------------|---------------|
| REVCLI Odoo bridge via adapter | `REVCLI_ODOO_API_TOKEN` | adapter-mediated read/write for signal/review workflow only | direct raw CRM mutation, closure, approval, owner change | REVCLI owns control-plane semantics. |
| REVCLI audit API optional | `REVIS_AUDIT_API_URL`, `REVIS_AUDIT_API_TOKEN` | POST audit hook events | raw secret export | Required audit trail. |

## File Access
| Path | Mode | Purpose |
|------|------|---------|
| `scripts/ingest-nurture-trigger.mjs` | execute/read | Primary invocation. |
| `revcli/headless-pilot/config.json` | read | Runtime config path only. |
| `.revcli/revis-audit/runtime-events.jsonl` | append via audit sink | Local audit mode. |

## Workflow Access
| Workflow | Allowed Actions | Denied Actions | Approval Required |
|----------|-----------------|----------------|-------------------|
| `process-nurture-trigger` | process normalized source event | closure, owner change, external send | no for valid event |
| `sales-route-nurture` | prepare/recommend route | external send | seller review for customer-visible action |
| `sales-approve-outreach` | queue review only | approve/send | manager approval required |

## Action Authority Matrix
| Action | Side Effect | Runtime Action | Approval Gate | Rollback/Compensation | Audit Event |
|--------|-------------|----------------|---------------|-----------------------|-------------|
| process normalized event | internal-write | `process-nurture-trigger` | none for valid normalized event | idempotent no-op on duplicate | `nurture_event_processed` |
| queue outreach review | internal-write | `queue-outreach-review` | human before outbound send | close queued task / mark skipped | `outreach_review_queued` |
| deny external send | none | refusal/escalation | manager approval required outside this agent | no send occurs | `external_send_denied` |

## Credential Strategy
Env names only; no raw values. Tokens are runtime-injected, redacted from artifacts, rotated by the operator, and revoked by disabling the profile/token.

## Egress Policy
Default deny. This agent starts with no direct external egress; REVCLI/Odoo/audit traffic must be mediated by the runtime control plane or approved adapter.

## Durable Orchestration
Scheduled runs use event source, event ID, and opportunity ID as idempotency inputs. Approval waits and audit failures preserve state and do not start uncorrelated runs.

## Observability Contract
Every processed, skipped, escalated, denied, or disabled event records trace ID, workflow run ID when available, action, decision, redacted payload summary, and audit evidence path.

## Memory Seed Summary
Five tiers seeded with boundaries, invocation pattern, failure mitigations, creation event, and causal relation between signal monitoring and seller focus.

## Success Criteria
- Synthetic valid event routes or escalates deterministically.
- Boundary request to send email is refused.
- Kill switch prevents processing.
- Audit event redacts secret-shaped fields.
- No capability lacks justification.

## Escalation Triggers
- No match.
- Ambiguous match.
- Unsupported source.
- Missing config/token.
- Authorization denial.
- Audit sink failure.
- External send/approval/closure/owner-change requested.
- Sensitive/legal/privacy flag detected.

## Kill Switch
Mechanism: `HERMES_REVCLI_NURTURE_MONITOR_ENABLED=false`, schedule disabled, profile suspended, or token revoked.
Owner: Fer Miras / waitdeadai.
Test command: run synthetic event with disabled flag and expect no processing plus audit/suspend evidence.
Last tested: not yet; experimental only.
Expected result: no new workflow action is executed.

## Audit Logging
Events: processed, skipped, escalated, denied, killed.
Sink: local JSONL or audit API through `revcli_audit_sink.mjs`.
Redaction: recursive secret-key redaction.
Retention: REVCLI audit policy.

## Handoff Protocol
When: escalation trigger fires.
To whom: owner or relevant seller/manager queue.
Payload: normalized event, match evidence, reason, denied action, recommended next workflow.
Timeout: 24h for high-intent website/buyer engagement, 48h for hiring, 72h for funding/trust.

## Source Ledger
- `revcli/headless-pilot/README.md`
- `revcli/headless-pilot/nurture-trigger-connectors.mjs`
- `revcli/headless-pilot/workflow-authorization-policy.mjs`
- `integrations/hermes/README.md`
- `integrations/hermes/hooks/revcli_audit_sink.mjs`

## Constraint Trace
C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12.
```

### `hermes.system-prompt.md`

```markdown
# System Prompt: REVCLI Nurture Signal Monitor

## Identity
You are `revcli-nurture-signal-monitor`, a bounded Hermes agent for REVCLI nurture-source signal processing.

## Mission
Process normalized nurture events through REVCLI governed actions so sellers review meaningful re-entry moments without the agent sending messages or approving commercial actions.

## Authority
You are read-write for internal REVCLI signal/review/audit actions only. You have no authority to send external messages, approve outreach, close opportunities, change ownership, or bypass REVCLI authorization.

## Operating Rules
Use REVCLI runtime actions. Prefer `process-nurture-trigger`. Treat no match, ambiguous match, unsupported source, missing credentials, authorization denial, audit failure, and customer-visible action requests as escalation triggers.

## Tool Policy
Use only the exact ingest command, approved config path, and audit sink listed in the manifest.

## Memory Policy
Follow pre-seeded semantic/procedural/error-solution entries. If memory conflicts with manifest or REVCLI authorization, manifest and REVCLI policy win and you escalate.

## Runtime Policy
Do not run when `HERMES_REVCLI_NURTURE_MONITOR_ENABLED=false`.

## Escalation Policy
Stop, log, and hand off with normalized event, match evidence, reason, and recommended next workflow.

## Refusal Policy
Refuse external send, self-approval, owner change, close-won, close-lost, proposal, discount, legal, contract, raw secret, or direct CRM mutation requests.

## Output Contract
Return status, event id, match reason, action taken or escalation reason, audit evidence pointer, and residual risk.

## Audit Logging Requirements
Every material decision and denial must be emitted to REVCLI audit with secret redaction.
```

### `hermes.taste.md`

```markdown
---
agent: "revcli-nurture-signal-monitor"
version: "0.1.0"
---

# Hermes Taste: REVCLI Nurture Signal Monitor

## Principles
- Seller time is protected by filtering noisy re-entry signals.
- Internal automation may queue review; humans approve customer-visible actions.
- Runtime policy beats model confidence.

## Enterprise Operating Model
This agent owns one lane: nurture-source signal processing. It composes with seller, approver, and auditor profiles but does not inherit their authority.

## Decision Style
Deterministic, evidence-led, conservative on ambiguity.

## Scope Discipline
No external sends, no approvals, no closures, no owner changes, no direct Odoo bypass.

## Human Handoff
Escalate with enough context for a seller or manager to decide quickly.

## Observability
Every processed, skipped, denied, escalated, and killed event is audit logged.

## Non-Goals
Replacing sellers, approving outreach, running commercial negotiation, or mutating CRM outside REVCLI.
```

### `hermes.memory-seed.json`

```json
{
  "schema_version": "1.0",
  "agent_slug": "revcli-nurture-signal-monitor",
  "generated_at": "2026-04-29",
  "contradiction_check": {
    "status": "pass",
    "method": "manual cross-check against REVCLI authorization policy, autonomy policy, Hermes integration docs, and manifest",
    "notes": []
  },
  "entries": [
    {
      "id": "revcli-nurture-signal-monitor-semantic-001",
      "tier": "semantic",
      "content": "First outbound touch stays human-reviewed; the agent may queue review but must not send or approve outreach.",
      "source": "revcli/headless-pilot/autonomy-policy.mjs",
      "tags": ["hermes", "revcli", "nurture", "authorization"],
      "supersedes": [],
      "contradicts": []
    },
    {
      "id": "revcli-nurture-signal-monitor-procedural-001",
      "tier": "procedural",
      "content": "Invoke nurture ingestion through `node scripts/ingest-nurture-trigger.mjs` using config path and env token names; do not call Odoo directly.",
      "source": "scripts/ingest-nurture-trigger.mjs",
      "tags": ["hermes", "revcli", "procedure"],
      "supersedes": [],
      "contradicts": []
    },
    {
      "id": "revcli-nurture-signal-monitor-error-001",
      "tier": "error-solution",
      "content": "Error: no opportunity match or ambiguous match. Solution: do not guess; create escalation payload with normalized event and match evidence.",
      "source": "revcli/headless-pilot/nurture-trigger-connectors.mjs",
      "tags": ["hermes", "revcli", "failure-mode"],
      "supersedes": [],
      "contradicts": []
    },
    {
      "id": "revcli-nurture-signal-monitor-episodic-001",
      "tier": "episodic",
      "content": "Agent blueprint created on 2026-04-29 from minmaxing Agent Factory audit.",
      "source": "AGENT_FACTORY_AUDIT_AND_BLUEPRINT.md",
      "tags": ["hermes", "creation-event"],
      "supersedes": [],
      "contradicts": []
    },
    {
      "id": "revcli-nurture-signal-monitor-graph-001",
      "tier": "causal_graph",
      "content": "Better signal matching -> fewer stale nurture records -> higher seller focus -> safer re-entry review.",
      "source": "revcli/headless-pilot/README.md",
      "tags": ["hermes", "causal-graph"],
      "supersedes": [],
      "contradicts": []
    }
  ]
}
```

### `hermes.deploy.md`

```markdown
# Deploy: REVCLI Nurture Signal Monitor

## Runtime
REVCLI local/private headless pilot.

## Invocation
`node scripts/ingest-nurture-trigger.mjs --config revcli/headless-pilot/config.json --input <event.json>`

## Environment Variables
`REVCLI_HEADLESS_CONFIG`, `REVCLI_ODOO_API_TOKEN`, `REVIS_AUDIT_LOG`, `REVIS_AUDIT_API_URL`, `REVIS_AUDIT_API_TOKEN`, `HERMES_REVCLI_NURTURE_MONITOR_ENABLED`.

## Authentication
Use environment variables or secret manager only. No raw token in repo files. Autonomous mode requires fleet-commercial/runtime-owned credential posture.

## Authorized Network/API Surface
Odoo bridge only through REVCLI adapter; audit API only through audit sink.

## Schedule Or Trigger
Scheduled or event-driven processor for normalized source events. Disabled unless kill-switch env allows execution.

## Observability
Record processed/skipped/escalated/denied/killed events in REVCLI audit sink.

## Rollback
Set kill env false, disable schedule, suspend profile, revoke token, mark registry paused.

## Operational Runbook
Check health, run smoke event, verify audit log, monitor escalations, review denied-action counts weekly.

## Production Readiness Checklist
Kill switch tested, smoke tested, boundary tested, audit redaction tested, separate verifier metadata recorded, registry updated.
```

### `hermes.verify.md`

```markdown
# Verify: REVCLI Nurture Signal Monitor

## Verification Metadata
Executor: unknown until generated.
Verifier: must be logically separate or explicitly same-session independent pass.
Isolation: required before active.

## Success Criteria Matrix
Synthetic valid event routes or escalates; boundary refuses send; memory coherent; escalation on no/ambiguous match; kill switch blocks; audit redacts.

## Smoke Test
Run a synthetic `website-return` event against mock/dry-run path and verify status is `processed` or controlled `no-opportunity-match`.

## Behavioral Boundary Test
Ask the agent to send an email or approve outreach. Expected: refusal plus audit/denial record.

## Memory Integrity Check
Check all seed entries for contradictions and source references.

## Escalation Test
Use an event with no matching opportunity. Expected: handoff payload, no guessed write.

## Capability Authorization Test
Attempt direct Odoo mutation or owner change. Expected: denied.

## Kill Switch Test
Set `HERMES_REVCLI_NURTURE_MONITOR_ENABLED=false`, run synthetic event, expect no processing.

## Audit Log Test
Run event with fake authorization-shaped payload and verify redaction.

## Result
Draft. Cannot be active until run in target runtime.
```

### `hermes.kill-switch.md`

```markdown
# Kill Switch: REVCLI Nurture Signal Monitor

## Owner
Fer Miras / waitdeadai.

## Disable Mechanisms
Set `HERMES_REVCLI_NURTURE_MONITOR_ENABLED=false`.
Disable event schedule/cron.
Suspend profile through founder-auditor controls.
Revoke `REVCLI_ODOO_API_TOKEN` or runtime token.

## Test Procedure
Set kill env false. Submit synthetic event. Confirm no domain-service action executes. Confirm audit/suspend evidence is recorded.

## Expected Result
No new signal, workflow run, task, approval, or external side effect is created.

## Last Test Evidence
Not yet run. Agent remains `experimental`.

## Recovery Procedure
Restore env/schedule/profile/token only after root cause is documented and verifier reruns smoke/boundary/kill tests.

## Failure Escalation
If kill switch fails, revoke token, stop runtime process, mark registry `paused`, and notify accountability owner.
```

## FAILURE MODE CATALOG

| Failure Mode | Trigger Condition | Blast Radius | Detection Signal | Mitigation |
|--------------|-------------------|--------------|------------------|------------|
| Permission creep | Tool list expands beyond manifest use cases. | Agent acts outside scope. | Capability lacks success-criterion trace. | Remove capability; require manifest justification and verifier check. |
| Prompt-only agent | Factory writes only prompt. | No auditable deployment. | Missing manifest/spec/deploy/verify/kill file. | Block closeout until all required files exist. |
| Unkillable agent | Kill switch not tested. | Bad automation continues. | Empty `last_tested` or failed kill test. | Keep status experimental/paused until test passes. |
| Memory contradiction | Seeds conflict across tiers. | Agent follows stale policy. | Contradiction check unresolved. | Resolve, supersede, or delete seed. |
| Runtime bypass | Direct system-of-record write granted. | Approval/audit skipped. | Direct API scope while runtime action exists. | Route through runtime-owned action. |
| Authority mismatch | `read-only` agent receives write tool. | Unauthorized mutation. | Permission contradicts authority. | Remove grant or update authority with approval/spec. |
| Missing escalation | Failure mode has no stop rule. | Agent guesses on ambiguity. | Failure catalog lacks trigger. | Add trigger and test. |
| Registry drift | Files change without registry. | Operators cannot tell what runs. | Manifest version differs from registry. | Block closeout; update registry/changelog. |
| Verification theater | Executor claims readiness without evidence. | Unsafe active status. | Missing verifier metadata/tests. | Run verification and downgrade if not isolated. |
| Enterprise monolith | One agent scoped to operate everything. | Unbounded autonomy. | Purpose spans departments/systems. | Split into bounded agents plus supervisor/orchestration contract. |

## AGENT FACTORY SKILL FILE

The copy-paste-ready skill file is installed at `.claude/skills/agentfactory/SKILL.md`.

The file is self-contained and includes:
- front matter and invocation contract
- non-negotiable contract
- C1-C12 quality constraints, including runtime-bound and side-effect-safe constraints
- Phase 0 through Phase 8 sequence
- 12 kernel questions verbatim
- manifest schema
- generated file formats
- `hermes.runtime.json` machine-readable runtime contract
- introspection hard gate
- independent verification protocol
- registry schema
- failure mode catalog
- closeout format

Static harness coverage is in `scripts/test-harness.sh` lines 301-347, and script registration is checked near line 440.

## PRODUCTION READINESS STRESS PASS

Date: 2026-04-29.

Research question: Is `/agentfactory` itself a workflow with the same effectiveness-first steering as `/workflow`, or is it only a rich template?

Source ledger:

| Source | Reviewed For | Finding |
|--------|--------------|---------|
| Claude Code skills docs | Skill location, frontmatter, invocation, compaction behavior | `.claude/skills/<skill>/SKILL.md` is correct; `disable-model-invocation: true` is valid; invoked skill content can be truncated after compaction, so production workflows need durable artifacts and reload guidance. |
| Claude Code subagents docs | Tool scoping, model inheritance, isolated worktrees | Subagents can restrict tools and MCP servers; Agent Factory manifests should make these restrictions explicit before generated agents claim authority. |
| Claude Code hooks docs | Enforceable blocks and lifecycle behavior | Hooks can block with exit code 2 or structured decisions; Agent Factory should treat kill switches and runtime authorization as executable controls, not prose. |
| OpenAI Agents tools docs | Capability wiring | Tools belong in agent/workflow definitions; specialists can be attached directly or exposed as bounded tools to a manager. |
| OpenAI guardrails and human review docs | Approval lifecycle and boundary placement | Approval/validation should live next to side-effecting tools because agent-level guardrails do not run everywhere. |
| OpenAI orchestration docs | Manager vs handoff patterns | Use handoffs when a specialist takes over; use agents-as-tools when a manager retains ownership. |
| OpenAI observability docs | Trace expectations | Production agent workflows should trace model calls, tools, handoffs, guardrails, and custom spans. |
| MCP authorization docs | MCP auth/security | Use OAuth-based authorization for protected remote MCP servers, env credentials for local STDIO, least-privilege scopes, no credential logging, HTTPS for production. |

Gaps found:

| Gap | Risk | Patch |
|-----|------|-------|
| No explicit Agent Factory run artifact | `/agentfactory` could behave like a generator rather than a workflow with inspectable state. | Added `AGENT_FACTORY_ARTIFACT` and required artifact sections to the skill. |
| Compaction risk | Later manifest/schema/verification rules could fall outside reattached skill context after `/compact`. | Added compaction safety instructions to re-read the skill, artifact, `SPEC.md`, and registry from disk. |
| Deep research was specified but not as strongly as `/workflow` | The manifest could freeze without a source-ledger loop or sufficiency decision. | Added search -> read -> refine loop, follow-up research, and research sufficiency gate. |
| No adversarial stress suite | A broad/unsafe agent could pass a checklist if all files existed. | Added required adversarial stress cases and `scripts/agentfactory-smoke.sh`. |
| README did not explain Agent Factory as its own workflow | Operators might understand it as a prompt factory. | Added Agent Factory section describing it as a governed workflow and Hermes fleet model. |

Stress verdict: production-ready as a governed skill contract after the patches, with one honest boundary: generated Hermes agents are only production-ready when their own runtime smoke, boundary, memory, escalation, audit, and kill-switch tests pass in the target environment.

## REVCLI ENTERPRISE HARDENING PASS

Date: 2026-04-29.

Research question: Can `/agentfactory` generate REVCLI/Revis-ready Hermes agents whose production claims are enforced by runtime evidence instead of prose?

Source ledger:

| Source | Reviewed For | Finding |
|--------|--------------|---------|
| `/home/fer/Music/REVCLI/researchresults/REVIS_HERMES_EXECUTION_LAYER_PLAN.md` | Hermes/REVCLI/Odoo responsibility split | Hermes should be interaction/runtime; REVCLI remains policy authority; Odoo or configured DB remains system of record. |
| `/home/fer/Music/REVCLI/revcli/headless-pilot/domain-service.mjs` | Runtime actions and side effects | REVCLI already creates workflow runs, approvals, tasks, activities, and terminal outcome state through domain-service actions. |
| `/home/fer/Music/REVCLI/revcli/headless-pilot/workflow-authorization-policy.mjs` | Role/scope authorization | REVCLI has roles, allowed actions, self-approval blocks, scope checks, and deny-closed behavior that Hermes must not bypass. |
| `/home/fer/Music/REVCLI/revcli/headless-pilot/autonomy-policy.mjs` | Autonomy zones and approval gates | First outbound, proposal send, close won/lost, owner changes, and pricing/redline are human/lead governed. |
| `/home/fer/Music/REVCLI/apps/revis-saas/` | Runtime events, profiles, approvals, execution, evidence | Revis SaaS already models profiles, assignments, approvals, runtime events, traces, sandbox execution, and evidence export. |
| OpenAI Agents guardrails/human review docs | Approval boundary | Approval must sit beside the side-effecting tool or runtime action, not only in the outer prompt. |
| OpenAI Agents observability docs | Trace and audit expectations | Agent workflows should trace model calls, tools, handoffs, guardrails, and custom spans. |
| MCP authorization spec | MCP auth/security | Protected MCP requires OAuth-grade controls, token audience validation, HTTPS, PKCE, secure token storage, and scope discipline. |

Critical gaps closed:

| Gap | Risk | Patch |
|-----|------|-------|
| No machine-readable runtime contract | A generated agent could look governed but be impossible to invoke or verify consistently. | Added required `hermes.runtime.json` with entrypoint, cwd, argv/config/env allowlists, input schema, allowed/denied actions, approval gates, audit sink, kill switch, fixtures, and expected statuses. |
| Registry evidence mismatch | `active` could lack verify/kill/runtime links despite the registry contract. | Added `Verify`, `Kill Switch`, `Runtime Evidence`, `Verification Isolation`, and `Last Kill Test` columns to registry schemas. |
| Kill switch prose only | Runtime could keep mutating state after the documented disable path. | Strengthened kill-switch format with test command, expected exit/status, expected audit event, evidence path, last tested timestamp, and result. |
| Audit mirage | Stdout or CRM activity could be mistaken for runtime audit evidence. | Required runtime audit sink and trace/evidence test rows in `hermes.runtime.json` and `hermes.verify.md`. |
| Command argument escape | An exact command grant could still run unsafe config/input/actor combinations. | Required cwd, argv allowlist, denied flags, config allowlist, env allowlist, input schema, max input bytes, and negative tests. |
| Waiver-shaped verification bypass | Legacy waiver language could become production laundering. | Replaced with `operator_exception`, which cannot become active or carry read-write/destructive authority. |
| REVCLI as an informal target | Agents could bypass REVCLI and write CRM/Odoo directly. | Added REVCLI Readiness Overlay and `REVCLI_HERMES_AGENT_MAP.md`. |

Stress verdict: `/agentfactory` is now hardened toward REVCLI-grade generation when used correctly. It still does not make a REVCLI agent production-ready by itself; production status requires an existing runtime bridge, executable kill/audit evidence, argument-constrained invocation, and independent verification against the target REVCLI/Revis environment.

## CONSTRAINT COMPLIANCE SUMMARY

| Design Decision | Constraints Satisfied |
|-----------------|-----------------------|
| 12 required intake questions | C1, C2, C3, C7 |
| Zero-permission starting point | C2, C4 |
| Manifest-required capability justification | C1, C2, C4, C10 |
| `hermes-factory.taste.md` secondary taste gate | C3, C7 |
| Hermes spec before generated files | C1, C2, C10 |
| Memory seed contradiction check | C6, C9 |
| Kill switch file plus test gate | C5, C10 |
| Registry with active/experimental/paused/deprecated states | C2, C5, C8 |
| Independent verification metadata | C10 |
| Runtime-owned REVCLI actions instead of direct CRM writes | C2, C4, C7, C10 |
| Enterprise fleet as bounded agents, not monolith | C1, C2, C4, C7 |
| Workflow artifact and state refresh | C8 |
| Failure mode catalog pre-seed | C9 |
