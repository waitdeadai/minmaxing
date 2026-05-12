---
name: hive
description: Coordinate a governed hive of specialized agents for broad research, planning, review, or implementation work when roles, blackboard state, dissent, synthesis, and verification materially improve the outcome.
argument-hint: [task]
disable-model-invocation: true
---

# /hive

Coordinate a governed multi-agent hive for:

$ARGUMENTS

`/hive` is a coordination mode, not a new execution engine.

It sits above `/parallel` and adds role assignment, blackboard discipline,
dissent, synthesis, and arbitration. When execution packets need workers,
`/hive` reuses `/parallel` packet DAGs, ownership matrices, sidecars, and
aggregation instead of inventing a second worker format.

## Command Boundary

- `/metacognition`: decides whether hive coordination is useful.
- `/hive`: coordinates multiple specialized agents around shared evidence.
- `/parallel`: executes independent packets with ownership and aggregation.
- `/hiveworkflow`: runs the full file-changing lifecycle with hive
  coordination.
- `/agent-view`: optional operator-managed visibility for independent Claude Code
  background sessions. It is not hive coordination and does not satisfy
  blackboard, dissent, aggregation, or verification requirements.
- `/workflow`: remains the default single-supervisor lifecycle.
- `/introspect`: remains the hard-gate audit. Hive consensus never replaces it.

Use `/hive` when a task benefits from multiple independent perspectives,
research branches, adversarial reviews, or role-specialized work packets.
Downgrade to `/workflow` or local work when the task is tightly coupled.

## Hive Vs Parallel

Pick `/parallel` when the problem is mostly execution throughput:

- independent packets
- owned files or surfaces
- sync barriers
- worker sidecars
- aggregate verification

Pick `/hive` when the problem is mostly judgment breadth:

- independent roles
- blackboard claims
- dissent or skeptic lanes
- synthesis and arbitration
- evidence-backed consensus checks

Pick `/hiveworkflow` when the task needs both coordinated judgment and the full
file-changing lifecycle. If the work only needs owned implementation packets,
use `/parallel`. If it only needs one supervisor loop, use `/workflow`.

For file-changing hive work, prefer `/opusworkflow` with
`inner_contract=hiveworkflow`. Use `/hive` directly for read-only coordination,
research, dissent, or synthesis where no files are changed.

## Non-Negotiable Contract

- The queen/supervisor owns route, scope, safety, final synthesis, and closeout.
- Agents receive bounded roles, evidence requirements, stop conditions, and
  owned files/surfaces when they may edit.
- The hive uses a visible blackboard artifact for claims, evidence, conflicts,
  decisions, locks, and open questions.
- Consensus is not evidence. Agreement only becomes usable when supported by
  source, repo, command, runtime, or verification evidence.
- Dissent is required for non-trivial decisions. If no dissent appears, run an
  explicit skeptic lane before synthesis.
- Shared-state edits require ownership, locks, or merge barriers.
- Worker and peer summaries are claims until the supervisor verifies them.
- `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and hardware ceiling are
  ceilings, not quotas.
- Agent teams are opt-in experimental only when capacity says they are
  available and the operator explicitly enables them.

## Hive Roles

Use the smallest useful role set:

| Role | Purpose | Typical Output |
| --- | --- | --- |
| `queen` | supervisor, route owner, final arbiter | synthesis and decision log |
| `scout` | independent research or repo discovery | source/evidence ledger |
| `builder` | bounded implementation packet | changed files and command evidence |
| `reviewer` | adversarial critique | risks, blockers, missing tests |
| `verifier` | independent proof lane | commands, runtime proof, pass/fail |
| `scribe` | blackboard and artifact keeper | durable hive artifact |

Do not create a role without a concrete evidence return.

## Capacity And Budget

Every hive run must read or cite:

```bash
bash scripts/parallel-capacity.sh --json 2>/dev/null || true
```

Compute:

```text
effective_hive_budget =
  min(MAX_PARALLEL_AGENTS, codex_max_threads, hardware_recommended_ceiling,
      independent_roles_or_packets, supervisor_review_capacity,
      verifier_capacity, blackboard_merge_capacity)
```

Use:

- `1`: local work; hive not useful.
- `2-3`: scout + reviewer, or scout + verifier.
- `4-6`: scouts/builders/reviewer/verifier with clear ownership.
- `7+`: broad audits or dense DAGs only when blackboard and verification can
  absorb the results.

Never claim linear speedup or that a larger hive is inherently smarter.

## Blackboard Artifact

Create a durable artifact for non-trivial hive runs:

```bash
mkdir -p .taste/workflow-runs
STAMP="$(date +%Y%m%d-%H%M%S)"
HIVE_ARTIFACT=".taste/workflow-runs/${STAMP}-hive.md"
```

Required sections:

```markdown
# Hive Run: [task]

## Task
## Metacognitive Route
## Capacity Profile
## Hive Eligibility
## Role Map
## Blackboard
## Dissent And Conflict Log
## Synthesis And Arbitration
## Packet DAG
## Verification Evidence
## Introspection
## Outcome
```

`## Blackboard` must include:

| Claim ID | Owner | Claim | Evidence | Status | Conflicts | Lock/Merge Barrier |
| --- | --- | --- | --- | --- | --- | --- |

Status values: `candidate`, `verified`, `rejected`, `blocked`.

### Machine-Readable Sidecar

When a hive run is used for planning, implementation, verification, or durable
learning, also write:

```text
.taste/hive/{run_id}/hive-run.json
```

Validate it before closeout:

```bash
bash scripts/artifact-lint.sh .taste/hive/{run_id}/hive-run.json
bash scripts/hive-aggregate.sh .taste/hive/{run_id}
```

The sidecar records `role_map`, `blackboard_claims`, `capacity`,
`dissent_log`, `synthesis`, `consensus_policy`, and `verification`.

## Hive Eligibility

Use hive only when all pass:

- independent roles or packets exist
- supervisor can review returned evidence
- blackboard can preserve provenance and conflict state
- verification can aggregate the result
- role prompts can be thin and current
- shared-state ownership or locks can be written

Downgrade when:

- one tight reasoning loop dominates
- all agents need the same context and files
- disagreement cannot be resolved with evidence
- tool or credential state is shared and risky
- verification depends on trusting peer summaries

## Coordination Protocol

1. Queen writes the route, budget, roles, blackboard schema, and stop conditions.
2. Scouts/reviewers/builders work in bounded lanes.
3. Scribe updates the blackboard from returned evidence.
4. Queen runs a sync barrier and checks stale context, conflicts, and locks.
5. If consensus appears, queen still checks evidence and dissent.
6. If conflict remains, queen arbitrates using evidence or downgrades/block.
7. Verifier proves the aggregate result.
8. `/introspect` attacks the synthesis before closeout.

## Relationship To `/parallel`

When hive work changes files or executes worker packets, reuse `/parallel`:

- packet DAG
- ownership matrix
- sync barriers
- `.taste/parallel/{run_id}/packet-dag.json`
- `.taste/parallel/{run_id}/ownership.json`
- `.taste/parallel/{run_id}/worker-results/*.json`
- `scripts/parallel-plan-lint.sh`
- `scripts/parallel-aggregate.sh`
- `scripts/artifact-lint.sh`
- `scripts/hive-aggregate.sh`

Hive adds cognition and coordination; `/parallel` remains the execution and
aggregation substrate.

Claude Code Agent View can help an operator monitor independent background
sessions used outside the hive or as manually managed `parallel-instances`, but
the hive still needs its own queen/supervisor, blackboard, dissent log, sidecars,
aggregation, and verification evidence. Agent View rows are operator status, not
verified hive claims.

## Output

```markdown
## Hive Decision
- Decision: local / hive-research / hive-review / hive-implementation / blocked
- Effective hive budget: N of ceiling M
- Roles: ...
- Blackboard: [path or not needed]
- Execution substrate: local / subagents / parallel-instances / agent-teams-experimental
- Dissent required: yes / no, reason
- Verification path: ...
- Route: /workflow / parallel / hiveworkflow / direct answer / blocked
- Confidence: high / medium / low, downgrade reason
```

## Anti-Patterns

- "Hive mind" as branding for unowned parallel work.
- Consensus without evidence.
- Majority vote as verification.
- Shared file edits without locks or merge barriers.
- Agents reading one another's unverified summaries as truth.
- Using every lane because the ceiling exists.
- Letting the hive replace `/introspect`, `/verify`, `/workflow`, or
  `/parallel`.
