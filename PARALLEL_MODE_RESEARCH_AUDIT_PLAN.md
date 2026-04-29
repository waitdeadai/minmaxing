# Parallel Mode Research, Audit, And Plan

## Executive Decision

Build `parallel` as a first-class minmaxing mode, not as a synonym for
`/sprint`.

Recommended public surface:

```text
/parallel "[dense task]"
```

Recommended internal role:

- `/parallel` is a whole-workflow orchestrator for dense work.
- The main agent is always the lead/orchestrator and keeps responsibility for
  taste alignment, research sufficiency, architecture decisions, `SPEC.md`,
  security/risk decisions, aggregation, verification decision, and closeout.
- Worker instances are bounded capabilities. They may research, audit, test,
  edit owned files, or review a specific surface, but they do not own the final
  user-facing decision.
- `/workflow` may route to `/parallel` when explicitly requested or when a task
  is dense and the user approves a parallel wave.
- `/sprint` remains the lower-level execution playbook for a single
  ownership-safe implementation wave.

This mirrors the repo's taste: separate orchestration from execution, keep
critical-path responsibility in the command that promised it, and use specialist
helpers without delegating away the contract.

## DeepResearch Brief

### Investigation Mode

`comprehensive`

Reason: the request affects central workflow architecture, skill behavior,
subagent coordination, verification, safety, and future dense-work execution.

### Collaborative Research Plan

Deliverable:

- A production-grade audit and implementation plan for a `parallel` mode that
  accelerates dense tasks while preserving minmaxing's gates.

Research branches:

- Official Claude Code subagent and agent-team behavior.
- Official OpenAI/Codex multi-agent orchestration, subagent, guardrail, and
  observability patterns.
- Current minmaxing workflow, sprint, autoplan, audit, verify, introspect,
  rules, settings, hooks, and Codex config surfaces.
- Failure modes specific to main/worker orchestration.

Source classes:

- Repo inspection.
- Project memory for prior minmaxing parallelism/surgical-diff decisions.
- Official Anthropic Claude Code docs.
- Official OpenAI/Codex docs.

Likely contradictions or unknowns:

- Claude Code agent teams are useful for coordination but experimental and
  disabled by default.
- Subagents preserve main context and have independent context windows, but
  normal subagents only report back to main rather than communicating peer to
  peer.
- Parallelism improves throughput only when packets are independent; otherwise
  it increases conflict, token cost, permission friction, and aggregation debt.

Stop condition:

- Enough evidence to decide whether `parallel` should be a new skill, how it
  composes with `/workflow` and `/sprint`, what gates it must enforce, and what
  implementation files need changes.

Research budget:

- Effective budget: 4 branches.
- Ceiling: `MAX_PARALLEL_AGENTS`/Codex `max_threads` is 10 in this repo.
- MiniMax MCP searches: unavailable in this Codex tool surface; fallback
  official web/docs sources were used.

### Research Tracks

| Track | Question | Evidence | Impact |
|-------|----------|----------|--------|
| Claude Code subagents | When should subagents be used? | Claude docs say subagents are useful when a side task would flood main context; each has its own context, tool access, prompt, and permissions. | Default `parallel` should use bounded subagents for research/audit/review packets that return summaries to the lead. |
| Claude Code agent teams | When do multiple full sessions make sense? | Claude docs say agent teams coordinate separate Claude Code sessions, are experimental, disabled by default, and best for parallel exploration, new modules, competing hypotheses, and cross-layer work. They also add token and coordination overhead. | Agent teams should be optional/experimental, not the default public `parallel` contract. |
| OpenAI orchestration | Should specialists take over or act as tools? | OpenAI orchestration docs distinguish handoffs from agents-as-tools; manager-style workflows fit when the manager synthesizes the final answer and specialists do bounded tasks. | `parallel` should be manager-led, not handoff-led. |
| Guardrails and observability | How should side effects and worker claims be controlled? | OpenAI docs recommend guardrails for automatic checks and human review before side effects; tracing/observability captures tools, handoffs, guardrails, and custom events. Claude hooks expose SubagentStart/Stop and task lifecycle events. | `parallel` needs packet manifests, sync barriers, worker result schemas, hook-ready evidence, and final verification. |
| Repo reality | What already exists? | `/workflow`, `/sprint`, `/autoplan`, `/audit`, `/verify`, `/introspect`, parallelism/delegation rules, `.codex/config.toml`, and state hooks already contain partial parallelism. | The implementation should integrate existing primitives rather than inventing a separate scheduler. |

### Loop Log

| Loop | What Changed | Why It Mattered |
|------|--------------|-----------------|
| Discovery | Found official Claude subagent/team docs and repo skills/rules. | Confirmed parallelism is already a repo principle but not a cohesive mode. |
| Deep read | Compared subagents, agent teams, OpenAI manager-style orchestration, and repo `/sprint`. | Clarified that main-led orchestration is the correct default; peer-coordinating teams are optional. |
| Pressure test | Audited hooks, Codex config, verification, and failure modes. | Found gaps around worker result schema, sync barriers, stale worker context, and final verification isolation. |

### Source Ledger

Cited sources:

- Claude Code subagents docs: separate context, tool access, permission control,
  context preservation, and note that agent teams are needed for multiple
  agents communicating in parallel.
  Source: https://code.claude.com/docs/en/sub-agents
- Claude Code agent teams docs: experimental status, use cases, subagents vs
  teams comparison, lead/teammate architecture, team size guidance, conflict
  avoidance, and limitations.
  Source: https://code.claude.com/docs/en/agent-teams
- Claude Code hooks docs: `PostToolBatch`, `SubagentStart`, `SubagentStop`,
  `TaskCreated`, `TaskCompleted`, async hook limitations, and security warning.
  Source: https://code.claude.com/docs/en/hooks
- OpenAI Agents orchestration docs: manager-style agents-as-tools when the
  manager synthesizes the final answer and specialists perform bounded tasks.
  Source: https://developers.openai.com/api/docs/guides/agents/orchestration
- OpenAI guardrails/human review docs: automatic guardrails and human review for
  sensitive side effects.
  Source: https://developers.openai.com/api/docs/guides/agents/guardrails-approvals
- OpenAI integrations/observability docs: tracing and runtime inspection before
  tuning workflows.
  Source: https://developers.openai.com/api/docs/guides/agents/integrations-observability
- Codex subagents docs: `max_depth`, `max_threads`, narrow custom agents, and
  structured CSV fan-out result collection.
  Source: https://developers.openai.com/codex/subagents

Reviewed but not cited:

- Codex workflows docs: useful for explicit context, verification, and cloud
  delegation patterns, but lower-signal than the subagent/orchestration docs
  for this specific mode.
  Source: https://developers.openai.com/codex/workflows
- OpenAI tools docs: useful for `parallel_tool_calls` and deferred tool loading,
  but this repo's problem is harness orchestration rather than raw tool APIs.
  Source: https://developers.openai.com/api/docs/guides/tools

Rejected/downweighted:

- Generic blog/forum posts on subagents: useful as practitioner color but not
  needed because official docs covered the core decisions.

### Key External Facts

- Subagents are best when a side task would flood the main conversation with
  logs, search results, or file contents; they keep a separate context and
  return a summary to the caller.
- If multiple agents need to communicate directly with each other, Claude Code
  agent teams are the official mechanism, but they are experimental and
  disabled by default.
- Agent teams are best for research/review, new modules/features, competing
  hypotheses, and cross-layer work; they add coordination overhead and token
  cost and are worse for sequential or same-file work.
- OpenAI recommends manager-style orchestration when one stable outer workflow
  should keep ownership and call specialists as bounded helpers.
- Guardrails and human review should protect sensitive side effects; parallel
  mode should not make side effects easier just because work is faster.
- Observability/tracing is essential because parallel systems produce more
  intermediate claims and failure states.

## Code Audit

### Current Parallelism Surfaces

| Surface | Current State | What Works | Gap For `parallel` Mode |
|---------|---------------|------------|--------------------------|
| `.claude/skills/workflow/SKILL.md` | Owns full lifecycle inline and allows subagents when useful. | Strong phase order, research/audit/spec/execute/verify gates, artifact requirements. | No explicit parallel eligibility gate, wave manifest, sync barriers, worker schema, or aggregation protocol. |
| `.claude/skills/sprint/SKILL.md` | Defines execution-only parallel wave with file isolation. | Clear effective budget, file ownership, anti-slot-filling stance. | Uses illustrative `claude -p` snippets, no tracked run manifest, no whole-workflow gating, no final verifier isolation protocol. |
| `.claude/skills/autoplan/SKILL.md` | Tags tasks `[PARALLEL]`, `[SEQUENTIAL]`, `[GATE]`. | Good SPEC-level task decomposition. | Does not enforce that execution follows the DAG or ownership matrix. |
| `.claude/skills/audit/SKILL.md` | Parallel audit tracks. | Good risk-based audit track list. | Final synthesis is mostly report-oriented; no reusable packet schema for broader mode. |
| `.claude/skills/deepresearch/SKILL.md` | Effectiveness-first research lanes. | Strong source ledger and loop protocol. | Not connected to downstream execution waves. |
| `.claude/skills/introspect/SKILL.md` | Can split introspection by risk surface. | Good hard gate. | Needs parallel-mode-specific risks: stale worker context, split-brain claims, same-file edits, aggregation bias. |
| `.claude/skills/verify/SKILL.md` | Evidence-first verification with isolation metadata. | Strong adversarial stance. | Needs aggregation verifier: verify workers' artifacts, not just final diff. |
| `.claude/rules/parallelism.rules.md` | Effective agent budget and packet requirements. | Exactly the right core primitives. | Needs promotion into first-class mode artifact and test harness. |
| `.claude/rules/delegation.rules.md` | Defines what to delegate and keep local. | Correctly keeps SPEC, architecture, security, verification decisions local. | Needs explicit mapping to `/parallel` main/worker contract. |
| `.codex/config.toml` | `max_threads=10`, `max_depth=1`. | Good ceiling and no recursive fan-out by default. | Needs docs tie-in so `parallel` uses both Claude `MAX_PARALLEL_AGENTS` and Codex `max_threads` consistently. |
| `.claude/settings.json` | Has `CLAUDE_CODE_SUBAGENT_MODEL` and `MAX_PARALLEL_AGENTS` is shell-derived. | Subagents model is configured; trusted local mode is explicit. | Does not enable experimental agent teams, which is good; docs should state this is intentional. |
| `.claude/hooks/*` | State hooks only; extra hook scripts exist but are not wired. | Compaction safety is preserved. | No subagent lifecycle, task lifecycle, or post-tool-batch observation yet. |
| `scripts/test-harness.sh` | Tests parallelism as a principle. | Prevents slot-filling regression. | No test for a first-class `/parallel` skill/mode. |

### Main Audit Findings

1. **Parallelism exists as a principle, not a mode.**
   The current system can parallelize research, planning, sprint execution,
   verification, and review, but each skill describes only its local slice. A
   dense-work mode needs one run artifact and one orchestration contract.

2. **`/sprint` is too narrow to become the public mode by itself.**
   It starts after tasks are already understood. The requested mode must begin
   at taste/research/audit and continue through spec, wave execution,
   aggregation, verification, and closeout.

3. **The main agent's non-delegable responsibilities are already known but not
   collected under a `parallel` contract.**
   `delegation.rules.md` says SPEC, architecture, security review, quality gate
   enforcement, scope negotiation, and verification decisions should not be
   delegated. `/parallel` should make that non-negotiable.

4. **No worker return schema exists.**
   Workers currently return prose summaries. Dense parallel work needs a stable
   packet result format so the lead can aggregate without losing evidence.

5. **No sync barrier semantics exist.**
   The future mode needs explicit barriers: research barrier, audit barrier,
   spec-freeze barrier, pre-write ownership barrier, implementation barrier,
   verification barrier, closeout barrier.

6. **No stale-context rule is enforced for workers.**
   Workers can begin from a thin brief, but if `SPEC.md`, owned files, or
   dependencies change while they run, they need a stop/re-sync condition.

7. **No current hook captures subagent lifecycle.**
   Claude Code exposes subagent and task lifecycle hooks, but this repo only
   uses state hooks. A later implementation can optionally add logging hooks;
   it should not require experimental teams to work.

8. **Agent teams should remain opt-in.**
   Official docs say teams are experimental and disabled by default. Enabling
   them in shared settings would be too aggressive for an OSS harness.

9. **Worktree isolation is absent.**
   For write-heavy parallel waves, same-workspace disjoint file ownership is
   enough for the first implementation. Worktrees can be phase two for complex
   multi-branch edits.

10. **Verification needs to check worker claims, not just final files.**
    Parallel mode adds a new failure mode: workers may overclaim, omit evidence,
    or produce incompatible partial fixes. Final `/verify` must inspect the
    packet artifacts and aggregation decisions.

## Recommended Architecture

### Public Mode

Create a new skill:

```text
.claude/skills/parallel/SKILL.md
```

Trigger language:

- `/parallel`
- "parallel this"
- "modo parallel"
- "dense workflow"
- "orchestrated parallel workflow"
- "main as orchestrator"

Do not rename `/sprint`. Keep `/sprint` as the execution wave primitive.

### Conceptual Model

```text
Main Orchestrator
  owns taste, route, research sufficiency, audit synthesis, plan, SPEC,
  packet DAG, file ownership, barriers, aggregation, verify decision, closeout

Worker Packets
  own only a bounded research/audit/test/edit/review surface
  receive thin context
  return structured evidence
  stop on conflicts, stale context, missing dependency, or boundary violation

Verifier
  validates SPEC criteria, final diff, packet evidence, aggregation decisions,
  and isolation metadata
```

### Phase Sequence

```text
PHASE 0: TASTE + CURRENT STATE GATE
PHASE 1: PARALLEL ELIGIBILITY AUDIT
PHASE 2: DEEPRESEARCH WAVE
PHASE 3: CODE AUDIT WAVE
PHASE 3.5: INTROSPECT PRE-PLAN
PHASE 4: PARALLEL PLAN + PACKET DAG
PHASE 5: SPEC.md + OWNERSHIP MATRIX
PHASE 5.5: PRE-WRITE BARRIER
PHASE 6: PARALLEL EXECUTION WAVES
PHASE 6.5: AGGREGATION + INTROSPECT POST-IMPLEMENTATION
PHASE 7: INDEPENDENT VERIFICATION WAVE
PHASE 8: CLOSEOUT + ARCHIVE
```

### Parallel Eligibility Gate

`/parallel` should proceed only when at least one condition is true:

- The task has 2+ independent research/audit branches.
- The task has 2+ disjoint file/surface ownership packets.
- The task has independent test/verification lanes that shorten the critical
  path.
- The task is a dense audit where separate risk lenses materially improve
  coverage.
- The task is an unclear investigation where competing hypotheses are useful.

`/parallel` should downgrade to normal `/workflow` or local execution when:

- Work lives in one file or one tight reasoning loop.
- File ownership cannot be made disjoint.
- Most tasks are sequential dependencies.
- The main cannot review all worker outputs coherently.
- The user only needs a quick answer or small patch.

### Effective Budget Formula

```text
parallel_budget = min(
  MAX_PARALLEL_AGENTS,
  codex.agents.max_threads,
  independent_packets,
  supervisor_review_capacity,
  available_verification_surfaces
)
```

Default recommendations:

- `1`: normal `/workflow`, not `/parallel`.
- `2-3`: dense local task with sidecar research/test/review.
- `3-5`: default dense workflow mode.
- `6-10`: only for broad audits, large independent docs/code surfaces, or
  many similar structured packets.

### Worker Packet Contract

Every packet must have:

```markdown
## Packet: [id]
- Type: research | audit | implementation | test | review | docs | migration
- Owner: [main/worker id]
- Owned files/surfaces: [...]
- Do not touch: [...]
- Inputs: SPEC.md, workflow artifact, source ledger, relevant files
- Dependencies: [...]
- Stop if: file overlap, stale SPEC, missing dependency, failed command,
  ambiguous authority, security concern, external side effect, conflict
- Success: objective definition of done
- Return format: packet result schema
```

### Worker Result Schema

```markdown
## Packet Result: [id]
- Status: success | partial | blocked | failed
- Files touched: [...]
- Evidence:
  - command/output/inspection links
- Claims:
  - [claim] -> [evidence]
- Deviations from packet brief:
  - [...]
- Freshness check:
  - SPEC hash/read time:
  - owned files hash/read time:
- Residual risks:
  - [...]
- Suggested next action:
  - accept | re-run | re-scope | escalate | block
```

For future automation, this can become JSON:

```json
{
  "packet_id": "impl-api-tests",
  "status": "success",
  "files_touched": ["tests/api/foo.test.ts"],
  "claims": [{"claim": "added regression coverage", "evidence": "npm test ..."}],
  "deviations": [],
  "residual_risks": [],
  "suggested_next_action": "accept"
}
```

### Run Artifact

Use a durable artifact:

```text
.taste/workflow-runs/${STAMP}-parallel.md
```

Required sections:

```markdown
# Parallel Run: [task]

## Task
## Taste Gate
## Parallel Eligibility Audit
## Research Wave Plan
## Research Wave Results
## Code Audit Wave Plan
## Code Audit Wave Results
## Introspection: Pre-Plan
## Parallel Plan
## Packet DAG
## Ownership Matrix
## SPEC Decision
## Execution Waves
## Packet Results
## Aggregation Notes
## Introspection: Post-Implementation
## Verification Wave
## Verification Metadata
## Outcome
```

### Main Orchestrator Non-Delegable Work

The main must keep:

- Taste gate and route decision.
- Research sufficiency decision.
- Architecture decisions.
- Security and side-effect decisions.
- Scope negotiation and non-goals.
- Active `SPEC.md` creation/update/reuse/archive decision.
- Ownership matrix approval.
- Sync barrier decisions.
- Aggregation acceptance/rejection.
- Final verification decision.
- Closeout, commit, push, deploy decisions.

### Worker-Allowed Work

Workers may own:

- Research branch with source ledger return.
- Code audit branch with file references and risk findings.
- Single implementation packet after SPEC freeze and ownership approval.
- Test writing/running for owned files.
- Documentation edits for owned docs.
- Reviewer lane on final diff or risk surface.

Workers may not:

- Edit `SPEC.md`.
- Expand scope.
- Touch unowned files.
- Run destructive commands.
- Change credentials/settings.
- Approve their own work as verified.
- Push, deploy, or close out.
- Spawn nested teams or recursive workers.

## Implementation Plan

### Phase 1: Add `/parallel` Skill

Files:

- Add `.claude/skills/parallel/SKILL.md`.
- Update `scripts/start-session.sh` skill list.
- Update `README.md`, `CLAUDE.md`, and `AGENTS.md`.

Content:

- Define trigger, purpose, non-negotiables, phase sequence, eligibility gate,
  budget formula, packet contract, result schema, barriers, and anti-patterns.
- Explicitly say `/parallel` is not `/sprint`; it may use `/sprint` as a lower
  execution playbook.
- Explicitly say agent teams are opt-in experimental, not default.

### Phase 2: Extend Existing Contracts

Files:

- `.claude/skills/workflow/SKILL.md`
- `.claude/skills/sprint/SKILL.md`
- `.claude/skills/autoplan/SKILL.md`
- `.claude/skills/introspect/SKILL.md`
- `.claude/skills/verify/SKILL.md`
- `.claude/rules/parallelism.rules.md`
- `.claude/rules/delegation.rules.md`

Changes:

- `/workflow`: route explicit `parallel`/`modo parallel` requests to the new
  mode contract, while preserving inline lifecycle ownership.
- `/sprint`: clarify it is an execution wave primitive and require structured
  packet results.
- `/autoplan`: require Packet DAG and Ownership Matrix when planning parallel
  execution.
- `/introspect`: add parallel-mode risk surfaces: stale worker context,
  split-brain claims, overclaiming, same-file conflict, hidden sequential
  dependency, aggregation bias.
- `/verify`: add packet-evidence verification before final accept.
- Rules: promote the packet contract and non-delegable decisions.

### Phase 3: Add Smoke Test

Files:

- Add `scripts/parallel-smoke.sh`.
- Update `scripts/test-harness.sh`.

Smoke assertions:

- `/parallel` skill exists and contains phase sequence.
- Skill contains "main orchestrator", "Parallel Eligibility Audit",
  "Packet DAG", "Ownership Matrix", "Worker Result Schema", "Sync Barrier",
  "agent teams are opt-in experimental", and "MAX_PARALLEL_AGENTS is a
  ceiling".
- README/CLAUDE/AGENTS mention `/parallel`.
- `scripts/start-session.sh` lists `/parallel`.
- Existing anti-patterns remain: no "always use full pool", no recursive
  fan-out, no delegated SPEC/security/final verification.

### Phase 4: Optional Lifecycle Hooks

Do not enable by default in the first implementation. Plan as optional:

- `SubagentStart`: append worker id/type/task to parallel artifact.
- `SubagentStop`: append result pointer/last summary to artifact.
- `TaskCreated`: block vague task names or missing ownership.
- `TaskCompleted`: block task completion without packet result schema.

Reason:

- Hooks run with local permissions and can add friction. The first `parallel`
  mode should be enforceable by skill contract and harness tests before adding
  hook complexity.

### Phase 5: Docs And Examples

Add one canonical example:

```text
/parallel "audit this repo for security, correctness, docs drift, and test gaps"
```

Expected behavior:

- Main creates artifact.
- Main chooses 4 lanes.
- Workers audit separate risk surfaces.
- Main synthesizes.
- Main writes or updates `SPEC.md` only if the user asked for fixes.
- Verification reads packet evidence and final claims.

## Verification Plan For Future Implementation

Run:

```bash
bash -n scripts/parallel-smoke.sh
bash scripts/parallel-smoke.sh
bash scripts/agentfactory-smoke.sh
bash scripts/test-harness.sh
git diff --check
```

Manual inspection:

- Check `/parallel` does not promise speed over correctness.
- Check `/parallel` preserves SPEC-first for file-changing work.
- Check `/parallel` does not enable experimental agent teams by default.
- Check main-owned decisions remain non-delegable.
- Check worker packets require owned files/surfaces and stop conditions.
- Check packet evidence is verified before final accept.

## Failure Mode Catalog

| Failure Mode | Trigger | Blast Radius | Detection | Mitigation |
|--------------|---------|--------------|-----------|------------|
| Slot-filling theater | Main spawns agents just because capacity exists. | Slower work, more noise, weaker synthesis. | Effective budget rationale does not map to independent packets. | Eligibility audit and budget formula. |
| Split-brain spec | Worker edits or reinterprets `SPEC.md`. | Implementation diverges from contract. | Packet result lists `SPEC.md` touched or claims new scope. | Main-only SPEC ownership. |
| Same-file collision | Two workers edit the same file. | Lost edits or incoherent diff. | Ownership matrix overlap. | Pre-write barrier blocks wave. |
| Stale worker context | SPEC or owned file changes while worker runs. | Worker output is obsolete. | Freshness hash/read-time mismatch. | Worker stop/re-sync condition. |
| Aggregation bias | Main accepts summaries without checking evidence. | False confidence. | Packet claims lack evidence. | Packet-evidence verification gate. |
| Recursive fan-out | Worker spawns more workers/teams. | Token blowup, uncontrolled authority. | Worker brief or result mentions nested delegation. | `max_depth=1`, no nested teams, main-only spawning. |
| Experimental team dependency | Mode requires Claude agent teams. | Broken behavior for default users. | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` absent. | Default to subagents; teams opt-in only. |
| Permission storm | Workers trigger many prompts. | User interruption and partial execution. | Repeated permission requests or blocked commands. | Prefer read-only workers; side effects main-gated. |
| Worker overclaim | Worker reports success without tests/evidence. | Bugs accepted. | Result schema missing command/output/inspection. | Verification rejects evidence-free packets. |
| Lead abandons workers | Main closes out before all packets finish. | Partial work and hidden failures. | Artifact has open packet statuses. | Closeout gate requires all packets accepted/blocked with reason. |

## Recommended First Implementation Slice

Smallest sufficient implementation:

- Add `/parallel` skill.
- Add `scripts/parallel-smoke.sh`.
- Add `scripts/parallel-capacity.sh` so the mode is aware of CPU/RAM,
  `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and experimental agent-team opt-in.
- Update docs and harness registration.
- Extend `/workflow`, `/sprint`, `/autoplan`, `/introspect`, `/verify`, and
  parallelism/delegation rules with references to `/parallel`.
- Extend `/agentfactory` so Hermes agents and fleets declare
  `development_host_profile`, `target_runtime_profile`,
  `host_capacity_profile`, `capacity_binding`, `concurrency_budget`,
  queue/backpressure behavior, and `degrade_policy`.
- Do not add hooks or worktree automation yet.

Why:

- This makes the contract first-class and testable without coupling the repo to
  experimental agent teams or brittle `claude -p` subprocess orchestration.

## Implementation Decisions

- Public command: `/parallel`. `/workflow` may auto-consider it for dense work,
  but there is no separate `/workflow --parallel` alias contract.
- Artifact location: `.taste/workflow-runs/*-parallel.md`, reusing the central
  workflow audit trail.
- Hook logging: deferred. The first production slice uses explicit artifacts and
  smoke tests rather than new hook behavior.
- Execution substrate: subagents by default, parallel-instances only with clear
  disjoint ownership and speed need, agent teams opt-in experimental only.
- Capacity awareness: implemented through `scripts/parallel-capacity.sh` for
  the development host and required target runtime evidence in
  AgentFactory/Hermes runtime contracts. Local PC specs never define cloud,
  VPS, CI, container, managed runtime, or REVCLI fleet capacity unless the
  target is explicitly local and bound to the dev host.
