---
name: hiveworkflow
description: Run the full minmaxing workflow with governed hive coordination: metacognitive route, deepresearch, role map, blackboard, packet DAG, aggregation, introspection, verification, and closeout.
argument-hint: [task]
disable-model-invocation: true
---

# /hiveworkflow

Run a governed hive workflow for:

$ARGUMENTS

`/hiveworkflow` is the end-to-end mode for tasks where coordinated specialized
agents materially improve the outcome. It is not the default path; plain
`/workflow` remains better for tightly coupled work.

For file-changing hive work, `/opusworkflow` is the default outer route and
`/hiveworkflow` is the inner contract. Direct `/hiveworkflow` invocation remains
valid, but it must inherit the Claude/Opus planner-reviewer plus
MiniMax-M2.7-highspeed executor policy before mutation.

```text
outer_route: opusworkflow
inner_contract: hiveworkflow
```

## Core Contract

For file-changing work, follow this order:

```text
taste gate -> metacognitive route -> hive eligibility -> deepresearch
-> code audit -> role map -> blackboard -> pre-plan /introspect -> SPEC.md
-> packet execution via /parallel when eligible -> aggregation
-> post-synthesis /introspect -> /verify -> closeout
```

Do not edit files before `SPEC.md` exists. Do not launch hive workers until role
map, blackboard schema, ownership/locks, packet DAG, and verification path are
written.

## When To Use

Use `/hiveworkflow` for:

- broad repo audits with independent surfaces
- dense implementation DAGs with clear file ownership
- multi-role planning where scouts, builders, reviewers, and verifiers improve
  quality
- high-stakes verification where dissent and independent proof reduce risk
- agent/fleet design where capacity, authority, and safety must be checked from
  multiple angles

Downgrade to `/workflow` when the work is one reasoning loop, one shared file,
or one continuous design decision.

## Artifact

Create:

```bash
mkdir -p .taste/workflow-runs
mkdir -p .taste/hive
STAMP="$(date +%Y%m%d-%H%M%S)"
HIVE_WORKFLOW_ARTIFACT=".taste/workflow-runs/${STAMP}-hiveworkflow.md"
HIVE_RUN_DIR=".taste/hive/${STAMP}"
mkdir -p "$HIVE_RUN_DIR"
```

Required section order:

```markdown
# Hive Workflow Run: [task]

## Task
## Taste Gate
## Metacognitive Route
## Hive Eligibility
## Deep Research Brief
## Code Audit
## Role Map
## Blackboard
## Dissent And Conflict Log
## Pre-Plan Introspection
## Plan
## Agent-Native Estimate
## SPEC Decision
## Packet DAG And Ownership
## Execution Notes
## Aggregation Evidence
## Post-Synthesis Introspection
## Verification Evidence
## Outcome
```

## Required Gates

- Capacity: cite `bash scripts/parallel-capacity.sh --json`.
- Budget: compute `effective_hive_budget`.
- Role map: every role has purpose, owner, inputs, output, stop condition, and
  verification.
- Blackboard: every claim has owner, evidence, status, conflicts, and lock or
  merge-barrier state.
- Sidecar: write `$HIVE_RUN_DIR/hive-run.json` and validate it with
  `bash scripts/artifact-lint.sh "$HIVE_RUN_DIR/hive-run.json"` plus
  `bash scripts/hive-aggregate.sh "$HIVE_RUN_DIR"`.
- Dissent: non-trivial synthesis has an explicit skeptic/reviewer lane.
- Packet execution: use `/parallel` sidecars and aggregation when workers edit
  files or run implementation packets.
- Introspection: `/introspect pre-plan` and post-synthesis/post-implementation
  hard gates still apply.
- Verification: `/verify` checks the aggregate result, not hive agreement.

## Closeout

Closeout must report:

- hive eligibility decision and any downgrade
- capacity profile and effective hive budget
- roles used and roles intentionally omitted
- blackboard path and claim counts by status
- conflicts, dissent, and arbitration outcome
- packet DAG and aggregation status when used
- verification commands and outcome
- unresolved risks and confidence downgrade

## Anti-Patterns

- Launching agents before the blackboard exists.
- Replacing `/parallel` aggregation with chat synthesis.
- Treating consensus as proof.
- Skipping `/introspect` because the hive reviewed itself.
- Adding hive workflow pauses unless the user asked for approval.
