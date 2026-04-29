---
name: agent-factory
description: Create governed Hermes agents as auditable enterprise operating units with manifest, capability stack, memory seed, deployment plan, verification contract, registry entry, and kill switch.
argument-hint: [Hermes agent intent]
disable-model-invocation: true
---

# /agent-factory

Create one governed Hermes agent for:

$ARGUMENTS

A Hermes agent is not a generic prompt. It is a purpose-built, self-contained autonomous operating unit with identity, scope, capabilities, memory, verification, deployment, handoff, audit trail, and a tested kill switch.

Hermes agents may be used as single workflow executors, department-specific assistants, or a coordinated enterprise operating layer. Even in a whole-company system, each Hermes agent must keep a narrow ownership boundary and escalate across boundaries instead of silently expanding authority.

## Non-Negotiable Contract

- Follow the phase sequence exactly: taste gate -> intent intake -> deep research -> manifest draft -> capability stack -> `HERMES-{NAME}-SPEC.md` -> file generation -> introspect -> verify -> closeout and registry.
- Start every new Hermes agent with zero permissions. Add only the tools, MCP scopes, APIs, files, and workflows proven necessary by research and the manifest.
- Do not create or deploy an agent whose purpose conflicts with `taste.md`, `taste.vision`, or `hermes-factory.taste.md`.
- Do not generate agent files before writing `HERMES-{NAME}-SPEC.md`.
- Do not mark an agent production-ready until the kill switch has executable test evidence.
- Do not accept contradictory memory seeds. Resolve or remove contradictions before file generation so every Hermes agent remains memory-coherent.
- Do not claim independent verification unless the verifier metadata proves a separate agent, process, model, workspace, or explicitly isolated same-session pass.
- Keep all output reproducible: the same intent answers and repo evidence must produce a functionally equivalent Hermes agent.
- Treat `revcli` or any other business runtime as the control plane when it already owns authorization, approval, audit, or system-of-record writes. Hermes agents call the runtime's governed actions instead of bypassing it.
- Keep `.minimaxing/state/CURRENT.md` updated enough that a `/compact` can resume without losing the active phase, open questions, generated paths, or verification status.

## Quality Constraints

| ID | Constraint | Factory Enforcement |
|----|------------|---------------------|
| C1 | Reproducible | Kernel questions, manifest schema, spec, and file formats are deterministic. |
| C2 | Auditable | Every capability grant has a manifest justification and verification evidence. |
| C3 | Malleable | Operators may override defaults, but every override is recorded in the manifest and spec. |
| C4 | Least privilege | Agents start with zero permissions; each permission is explicitly granted. |
| C5 | Killable | The kill switch must be documented, executable, and tested before production status. |
| C6 | Memory-coherent | Memory seeds require contradiction checks across semantic, procedural, error-solution, episodic, and causal graph tiers. |
| C7 | Taste-aligned | The purpose must pass project taste and factory taste gates. |
| C8 | Compaction-safe | Current phase, decisions, pending gates, and paths are recorded in `.minimaxing/state/CURRENT.md` or a workflow artifact before risky transitions. |
| C9 | Failure-cataloged | Agent Factory ships with a failure-mode catalog and seeds relevant error-solution entries for each agent. |
| C10 | Zero-trust verification | Readiness is decided by verification evidence, not executor confidence. |

## Agent Factory Workflow Artifact

Agent Factory is a workflow on its own, not a template generator. Every invocation must create and maintain a durable artifact before the Hermes manifest or spec is accepted:

```bash
mkdir -p .taste/workflow-runs
STAMP="$(date +%Y%m%d-%H%M%S)"
AGENT_FACTORY_ARTIFACT=".taste/workflow-runs/${STAMP}-agent-factory.md"
```

Required section order:

```markdown
# Agent Factory Run: {agent intent}

## Task
## Taste Gate
## Intent Intake
## Deep Research Brief
## Source Ledger
## Runtime Audit
## Manifest Draft
## Capability Stack
## Research Sufficiency Introspection
## Hermes SPEC Decision
## File Generation Notes
## Readiness Introspection
## Independent Verification Evidence
## Registry And Memory Closeout
## Outcome
```

Required behavior:
- `## Deep Research Brief` must follow the same effectiveness-first shape as `/workflow`: collaborative research plan, search -> read -> refine loop, source ledger, contradiction handling, and follow-up research before freezing the manifest.
- `## Source Ledger` must separate cited sources, reviewed-but-not-cited sources, and rejected/downweighted sources.
- `## Runtime Audit` must name the target runtime's auth, approval, audit, state, irreversible actions, and kill switch surfaces.
- `## Independent Verification Evidence` must record executor/verifier metadata and never overclaim isolation.
- `## Outcome` must state whether the agent is `draft`, `experimental`, `active`, `paused`, or `blocked`.

## Compaction Safety

Claude Code re-attaches only a bounded slice of invoked skill content after compaction. Treat this skill as compaction-sensitive:

- Before leaving any phase, write the current phase, pending gate, generated paths, source ledger status, and unresolved risks into `AGENT_FACTORY_ARTIFACT`.
- If resuming after `/compact`, `/resume`, or a stale `CURRENT.md`, re-read `.claude/skills/agent-factory/SKILL.md`, `AGENT_FACTORY_ARTIFACT`, `SPEC.md`, and `hermes-registry.md` before continuing.
- Never rely on memory of the skill body alone after compaction. Reload the file from disk when any later phase depends on the manifest schema, generated file formats, or verification requirements.

## Phase 0: Taste Gate

1. Read `taste.md` and `taste.vision`.
2. Read `hermes-factory.taste.md`. If it does not exist, create it before continuing with these required sections:
   - `principles`: least privilege, auditability, reproducibility, killability, bounded autonomy
   - `enterprise_operating_model`: Hermes agents are workflow-bounded operating units that may compose into department or company systems
   - `non_goals`: no omnipotent agent, no hidden credentials, no unmanaged business writes, no unverified production readiness
   - `approval_philosophy`: destructive, external, financial, legal, credential, or customer-visible actions require explicit approval unless the manifest proves bounded policy authorization
3. Check whether the proposed agent purpose aligns with `taste.md`, `taste.vision`, and `hermes-factory.taste.md`.
4. Record a taste decision:
   - `PASS`: proceed
   - `NEEDS_ALIGNMENT`: ask focused questions or update taste with explicit operator approval
   - `BLOCKED`: stop because the purpose contradicts taste
5. Update the workflow artifact with taste evidence and the decision.

Hard gate: `BLOCKED` stops the factory. Do not continue to intent intake.

## Phase 1: Hermes Intent Intake

Ask these 12 kernel questions verbatim before any research, planning, or agent file generation:

1. What is this Hermes agent's exact purpose in one sentence, with no weasel words?
2. What is the hard scope boundary: what will this agent NEVER do?
3. What decision authority level does it have: `read-only`, `read-write`, or `destructive-allowed`?
4. What escalation trigger makes it stop and ask a human?
5. What success metric will prove in 30 days that it is working?
6. What failure mode describes what a bad version of this agent looks like?
7. What target runtime environment will run it?
8. What memory must be pre-seeded before the first run?
9. What tools, MCP servers, APIs, files, and workflows is it explicitly authorized to use?
10. Who is the operator and accountability owner?
11. What deployment lifecycle does it use: `ephemeral`, `persistent`, or `scheduled`?
12. What is the kill switch, and how is it tested?

Rules:
- If any answer is missing, mark intake `INCOMPLETE`.
- If tool authorization says "whatever it needs", reject it and request an explicit list.
- If decision authority is `destructive-allowed`, require a separate approval policy and rollback proof.
- If the kill switch cannot be tested, the agent cannot be production-ready.

## Phase 2: Deep Research

Research before designing the Hermes agent. Use the smallest effective research budget that resolves material unknowns.

Required research branches:

| Branch | Required Evidence |
|--------|-------------------|
| Repo overlap | Existing agents, workflows, scripts, policies, profiles, skills, or runtime modules that overlap the intended purpose. |
| Runtime integration | How the target runtime invokes actions, stores state, handles auth, logs audit events, and applies approval policy. |
| Failure modes | Relevant existing error-solution memories plus newly identified failure modes for this agent category. |
| External best practices | Current official docs or primary sources for agent guardrails, MCP, auth, approvals, observability, and deployment patterns when the design depends on them. |
| Taste contradictions | Any mismatch between intended behavior and `taste.md`, `taste.vision`, or `hermes-factory.taste.md`. |

Research output must include:
- collaborative research plan
- iterative search -> read -> refine loop log
- effective research budget and why it was not inflated
- source ledger with cited, reviewed-but-not-cited, and rejected/downweighted sources
- repo evidence with file paths and line references when available
- contradictions and how they were resolved
- implications for manifest, capabilities, memory seed, verification, deployment, and kill switch
- follow-up research performed or an explicit reason it was not needed

Research sufficiency gate:
- `PASS`: evidence is enough to draft the manifest.
- `FIX_REQUIRED`: run another research loop before design.
- `REPLAN_REQUIRED`: the intended agent should be split, narrowed, or blocked.
- `BLOCKED`: unresolved runtime, auth, approval, data, legal, or destructive-action ambiguity prevents safe design.

Hard gate: unresolved auth, approval, destructive action, or system-of-record ambiguity blocks manifest drafting.

## Phase 3: Hermes Manifest Drafting

Draft `hermes.manifest.md` from the intake and research. The manifest is the agent identity and authority contract.

### Manifest Schema

Use Markdown with YAML front matter followed by required sections. Field names are lowercase snake_case.

| Field | Required | Type | Valid Values | Invalid When |
|-------|----------|------|--------------|--------------|
| `manifest_version` | yes | string | semantic version of manifest schema, default `"1.0"` | missing, empty, non-string |
| `name` | yes | string | human-readable name, 3-80 chars | vague, duplicate, includes secret |
| `slug` | yes | string | lowercase kebab-case, unique in registry | not kebab-case, duplicate |
| `version` | yes | string | semver like `0.1.0` | not semver |
| `status` | yes | enum | `experimental`, `active`, `paused`, `deprecated` | anything else |
| `created_at` | yes | string | ISO date `YYYY-MM-DD` | missing or invalid date |
| `operator` | yes | string | person or team that created the agent | missing |
| `accountability_owner` | yes | string | accountable human owner | missing |
| `purpose` | yes | string | one sentence, no "help with" or broad verbs alone | more than one sentence, vague |
| `scope_boundary` | yes | list[string] | explicit non-actions | empty |
| `non_goals` | yes | list[string] | excluded outcomes | empty |
| `decision_authority` | yes | enum | `read-only`, `read-write`, `destructive-allowed` | mismatch with capabilities |
| `target_runtime` | yes | string | local, CI, server, revcli, MCP, cloud, or named runtime | missing |
| `deployment_lifecycle` | yes | enum | `ephemeral`, `persistent`, `scheduled` | anything else |
| `capability_stack` | yes | list[object] | each object includes `type`, `name`, `scope`, `justification`, `risk`, `approval_required` | any permission lacks justification |
| `mcp_servers` | yes | list[object] | each object includes `name`, `transport`, `scopes`, `justification`, `approval_model` | broad scopes or missing approval model |
| `api_access` | yes | list[object] | each object includes `service`, `env_vars`, `allowed_methods`, `denied_methods`, `justification` | secret values included |
| `file_access` | yes | list[object] | each object includes `path`, `mode`, `purpose` | write access without reason |
| `workflow_access` | yes | list[object] | each object includes `workflow`, `allowed_actions`, `denied_actions`, `approval_required` | external side effects unapproved |
| `memory_seed` | yes | list[object] | each object includes `tier`, `id`, `content`, `source`, `contradiction_check` | contradiction unresolved |
| `success_criteria` | yes | list[string] | at least one objective, machine-checkable criterion | all criteria require human taste |
| `escalation_triggers` | yes | list[string] | concrete stop conditions | missing failure coverage |
| `kill_switch` | yes | object | includes `mechanism`, `owner`, `test_command`, `last_tested`, `expected_result` | untested for active status |
| `audit_logging` | yes | object | includes `events`, `sink`, `redaction`, `retention` | no runtime outcome logging |
| `handoff_protocol` | yes | object | includes `when`, `to_whom`, `payload`, `timeout` | missing owner or payload |
| `verification_status` | yes | enum | `draft`, `verified`, `failed`, `waived` | `verified` without evidence |
| `constraints` | yes | list[string] | references C1-C10 and project-specific constraints | empty |
| `source_ledger` | yes | list[object] | repo, memory, and external sources used | missing for non-trivial design |

Optional fields:

| Field | Required | Type | Valid Values | Invalid When |
|-------|----------|------|--------------|--------------|
| `parent_agent` | no | string | slug of supervisor agent | missing referenced registry entry |
| `child_agents` | no | list[string] | slugs of delegated agents | cyclic delegation |
| `schedule` | no | string | cron, interval, or event trigger | lifecycle is `scheduled` and schedule missing |
| `rollback_plan` | no | list[string] | concrete rollback steps | destructive authority and rollback missing |
| `cost_budget` | no | object | token, API, time, or spend limits | unbounded for persistent agent |
| `data_classification` | no | enum | `public`, `internal`, `confidential`, `restricted` | secrets treated as public |

Hard gate: no manifest field may contain raw secrets, passwords, tokens, customer-sensitive payloads, or hidden credential instructions.

## Phase 4: Capability Stack Design

Design capabilities using least privilege.

1. Start with an empty capability list.
2. Add a capability only when a specific success criterion cannot be satisfied without it.
3. For each tool, MCP server, API, file path, and workflow action, record:
   - exact name and scope
   - required use case
   - denied use cases
   - approval requirement
   - failure mode it introduces
   - verification test
4. Prefer runtime-owned actions over direct system-of-record writes when a governed runtime exists.
5. Prefer local/private MCP connections when the runtime must own filtering, credentials, approvals, or audit.
6. Use hosted MCP only when the remote tool is already policy-bounded and the model-level connection is appropriate.
7. Build the memory scaffold:
   - semantic tier: known decisions and operating boundaries
   - procedural tier: known runtime invocation patterns
   - error-solution tier: failure modes and mitigations
   - episodic tier: creation event and verification run
   - causal graph tier: relationships between agent purpose, capabilities, risk, and success metrics
8. Build the system prompt from the manifest, not freeform improvisation.

Hard gate: any capability without a manifest justification is removed before `HERMES-{NAME}-SPEC.md`.

## Phase 5: SPEC.md For The Hermes Agent

Write `.taste/hermes-agents/{slug}/HERMES-{SLUG}-SPEC.md` before generating agent files.

Required sections:

```markdown
# HERMES SPEC: {name}

## Purpose Contract
## Taste Alignment
## Runtime And Integration Surface
## Authority Model
## Capability Grants
## Memory Seed Contract
## Verification Contract
## Escalation And Handoff Contract
## Kill Switch Contract
## Audit And Observability Contract
## Security And Credential Contract
## Success Criteria
## Non-Goals
## Failure Modes
## Implementation Plan
## Independent Verification Plan
## Rollback Plan
## Constraint Trace
```

Hard gate: do not generate `hermes.manifest.md`, prompts, memory seed, deployment docs, or registry entries until the Hermes spec exists and matches the manifest draft.

## Phase 6: Agent File Generation

Generate files under `.taste/hermes-agents/{slug}/`.

Required files:

| File | Purpose |
|------|---------|
| `hermes.manifest.md` | Identity, authority, capabilities, owners, and source ledger. |
| `hermes.system-prompt.md` | Runtime behavioral kernel derived from the manifest. |
| `hermes.taste.md` | Agent-specific operating principles and non-goals. |
| `hermes.memory-seed.json` | Pre-seeded memory entries with contradiction checks. |
| `hermes.deploy.md` | Invocation, runtime, env vars, auth, schedules, observability, and rollback. |
| `hermes.verify.md` | Smoke, boundary, escalation, memory, and kill-switch tests. |
| `hermes.kill-switch.md` | Concrete disable mechanisms and last test evidence. |
| `HERMES-{SLUG}-SPEC.md` | Formal contract written before the generated files. |

### File Format: hermes.manifest.md

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
## Memory Seed Summary
## Success Criteria
## Escalation Triggers
## Kill Switch
## Audit Logging
## Handoff Protocol
## Source Ledger
## Constraint Trace
```

### File Format: hermes.system-prompt.md

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

### File Format: hermes.taste.md

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

### File Format: hermes.memory-seed.json

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
  "entries": [
    {
      "id": "{slug}-semantic-001",
      "tier": "semantic",
      "content": "Decision or boundary to preload.",
      "source": "manifest|repo|operator|research",
      "tags": ["hermes", "{slug}"],
      "supersedes": [],
      "contradicts": []
    }
  ]
}
```

### File Format: hermes.deploy.md

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

### File Format: hermes.verify.md

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

### File Format: hermes.kill-switch.md

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

### File Format: HERMES-{SLUG}-SPEC.md

Use the exact Phase 5 section list. The file must be created before the other generated files and archived to `.taste/specs/` during closeout.

## Phase 6.5: Introspect Hard Gate

Run introspection inline before readiness.

Required checks:
- Is every tool authorization justified by a specific use case in the manifest?
- Does the escalation trigger cover all identified failure modes?
- Is there at least one testable success criterion that does not require human judgment?
- Does the kill switch actually work, with test evidence, or is it only documented?
- Are there any permissions that contradict the declared decision authority level?
- Does the system prompt introduce authority not present in the manifest?
- Do memory seeds contradict each other across tiers?
- Does the deployment plan bypass the runtime's approval, audit, or system-of-record rules?

Decision:
- `PASS`: continue to independent verification.
- `FIX_REQUIRED`: correct files and re-run introspection.
- `REPLAN_REQUIRED`: revise manifest/spec/capability stack before regenerating.
- `BLOCKED`: stop and report the blocker.

## Phase 7: Independent Verification

Verify the Hermes agent against its spec.

Required tests:

| Test | What It Proves |
|------|----------------|
| Smoke test | The agent can be invoked in the target runtime and returns a scoped response. |
| Behavioral boundary test | The agent refuses or escalates tasks outside its scope. |
| Memory integrity check | Seed entries are coherent and non-contradictory across tiers. |
| Escalation test | The agent stops and hands off when a defined trigger occurs. |
| Capability authorization test | The agent cannot use tools or workflows outside its manifest. |
| Kill switch test | Disabling the agent prevents new work and leaves audit evidence. |
| Audit log test | Material decisions, actions, escalations, and outcomes are recorded. |

Required adversarial stress cases:

| Stress Case | Expected Result |
|-------------|-----------------|
| Purpose is too broad or spans multiple departments | Factory splits the intent or blocks as `Enterprise monolith`. |
| Tool authorization says "whatever it needs" | Factory rejects intake as incomplete. |
| Manifest contains raw secret material | Factory blocks before file generation. |
| `read-only` authority includes any write tool | Factory returns `FIX_REQUIRED`. |
| `destructive-allowed` lacks approval and rollback proof | Factory returns `BLOCKED`. |
| Runtime has governed action but manifest grants direct system-of-record write | Factory removes grant or blocks as runtime bypass. |
| Memory seed contradicts another tier | Factory blocks until superseded or resolved. |
| Kill switch is documented but untested | Agent cannot become `active`. |
| Registry row claims `active` without verification metadata | Factory downgrades status or blocks closeout. |
| Verifier is same session but reported as separate | Factory corrects metadata and downgrades confidence. |

Verification metadata must record:
- executor identity/model/workspace
- verifier identity/model/workspace
- isolation status: `proved separate`, `separate process`, `same session independent pass`, or `unknown`
- files inspected
- commands run
- criteria passed/failed
- residual risk

Hard gate: verification failure prevents `active` status. Use `experimental` only when residual risk is explicit and no production authority is granted.

## Phase 8: Closeout And Registry

1. Write the completed agent directory to `.taste/hermes-agents/{slug}/`.
2. Update `hermes-registry.md` at the project root.
3. Register each agent row with:
   - name
   - slug
   - purpose
   - version
   - status: `active`, `deprecated`, `experimental`, or `paused`
   - decision authority
   - lifecycle
   - operator
   - created date
   - last verified date
   - manifest link
   - spec link
4. Log creation to semantic memory:

```bash
bash scripts/memory.sh add semantic "Hermes agent created: {slug}. Purpose: {purpose}. Status: {status}. Owner: {owner}." --tags "hermes,agent-factory,{slug}"
```

5. Log Agent Factory failure modes relevant to this agent to error-solution memory.
6. Archive `HERMES-{SLUG}-SPEC.md` to `.taste/specs/` after verified closeout.
7. Update `.minimaxing/state/CURRENT.md` or the workflow artifact with final paths, verification result, and residual risks.

Hard gate: no registry entry may claim `active` unless `hermes.verify.md` records a passing kill switch test and independent verification metadata.

## hermes-registry.md Schema

Use this exact root file format:

```markdown
# Hermes Registry

## Registry Contract
- Source of truth for Hermes agents created by /agent-factory.
- Status values: active, deprecated, experimental, paused.
- Every active agent must link to manifest, spec, verification, and kill-switch evidence.
- Registry updates require /agent-factory or an explicit operator-approved maintenance change.

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
```

## Failure Mode Catalog For Agent Factory

Seed these entries into the Agent Factory error-solution tier and copy relevant entries into each agent's memory seed:

| Failure Mode | Trigger | Blast Radius | Detection Signal | Mitigation |
|--------------|---------|--------------|------------------|------------|
| Permission creep | Tool list expands beyond manifest use cases | Agent can act outside intended boundary | Capability without success-criterion trace | Remove capability; require manifest justification and verifier check. |
| Prompt-only agent | Factory writes only a system prompt | No deployable or auditable runtime | Missing manifest, spec, deploy, verify, or kill-switch file | Block closeout until all required files exist. |
| Unkillable agent | Kill switch documented but untested | Persistent bad automation continues | `last_tested` empty or kill-switch test failed | Keep status experimental/paused; test disable path before active. |
| Memory contradiction | Seeds conflict across tiers | Agent follows stale or opposing policy | Contradiction check reports unresolved entries | Resolve, supersede, or delete seed before generation. |
| Runtime bypass | Hermes writes directly to system of record | Approval/audit policies are skipped | Direct API scope exists while runtime action exists | Route through runtime-owned action; deny direct write. |
| Authority mismatch | `read-only` agent gets write tool | Business data changes despite read-only contract | Permission contradicts `decision_authority` | Remove permission or change authority with approval and spec update. |
| Missing escalation | Failure mode has no stop condition | Agent guesses through ambiguous/high-risk cases | Failure catalog entry lacks escalation trigger | Add trigger and test it. |
| Registry drift | Agent files change without registry update | Operators cannot tell what is running | Manifest version differs from registry | Block closeout; update registry and changelog. |
| Verification theater | Executor claims readiness without independent evidence | Unsafe agent becomes trusted | Missing verifier metadata or tests | Run verification; record isolation; downgrade status if not separate. |
| Enterprise monolith | One Hermes agent is scoped to run everything | Unbounded autonomy and unclear accountability | Purpose spans multiple departments or systems | Split into bounded agents plus supervisor registry/orchestration contract. |

## Closeout Format

Report:
- agent slug and path
- status and authority
- capability count and highest-risk capability
- verification result and isolation status
- kill-switch test result
- registry update result
- memory entries written or skipped
- residual risks
