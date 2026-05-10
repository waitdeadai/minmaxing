---
name: opusminimax
description: Advanced engine behind /opusworkflow for provider split, packet, repair, and benchmark work. Normal build/fix/refactor work should use /opusworkflow, which asks Opus 4.7 to plan/review when proven available and MiniMax-M2.7-highspeed to execute.
argument-hint: [task, mode: workflow|benchmark|repair]
disable-model-invocation: true
---

# /opusminimax

Run the governed Opus planner + MiniMax executor mode for:

$ARGUMENTS

Plain rule:

```text
If you are trying to build, fix, refactor, or ship a product, use /opusworkflow.
Use /opusminimax directly only for engine, provider, packet, repair, or benchmark work.
/opusworkflow is the human command; /opusminimax is the advanced engine.
```

Mode banner:

```text
Claude is planner, adversary, and reviewer.
MiniMax-M2.7-highspeed is executor for bulk coding.
Worker summaries are claims until verified by diffs, logs, tests, or artifacts.
```

## Non-Negotiable Contract

- Do not treat this as a model alias switch.
- Do not claim Opus planned, reviewed, or verified unless the planner profile,
  auth/model preflight, or runtime artifact proves it.
- Do not let the planner inherit `ANTHROPIC_BASE_URL=https://api.minimax.io/anthropic`.
- Do not run MiniMax execution from the planner phase unless the user explicitly
  enters the executor phase.
- Do not read `.env`, `.env.*`, `.claude/settings.local.json`,
  `.claude/*.local.json`, `secrets/**`, private credentials, customer artifacts,
  or MiniMax key files.
- Use `/deepresearch` for architecture, provider, benchmark, harness, or
  high-stakes implementation decisions. Use `/claudeproduct` first for Claude
  product facts.
- Treat local capacity, Codex `max_threads`, and `MAX_PARALLEL_AGENTS` as
  ceilings. Treat MiniMax Token Plan capacity as the executor bottleneck until
  verified.
- Default MiniMax executor concurrency to `1` unless provider-tier evidence
  proves a higher ceiling.
- If `executor_provider=claude-sonnet` is explicit, treat it as the optional
  Claude-only `/opussonnet` route: no MiniMax base URL, executor model must be
  Sonnet, and the run artifact must not imply MiniMax executed anything.
- If `model_profile=sonnet|opus|default|custom` is explicit, treat it as a
  governed Anthropic-only route: no MiniMax base URL, no MiniMax executor model,
  and no runtime model identity claim without `/status`, sentinel, or artifact
  proof.
- When `outer_route=opusworkflow`, record `plan_mode` in the run artifact.
  Default `plan_mode.policy=auto` means `auto_approved_when_gates_pass`: the
  workflow may transition from plan to execution only after research, code
  audit, `/introspect pre-plan`, Agent-Native Estimate, `SPEC.md`, and `/specqa`
  allow execution.
- Run `/introspect` before plan freeze, after executor execution, after failed
  verification, and before push or ship decisions.
- Run `/verify` against `SPEC.md` after executor aggregation.

## Phase 0: Provider And Capacity Preflight

Use static proof first:

```bash
bash scripts/opusminimax-doctor.sh --static
bash scripts/parallel-capacity.sh --json
```

When runtime planner execution is requested, diagnose and repair safe local
profile drift before model invocation:

```bash
bash scripts/opusminimax-doctor.sh --runtime --fix-local-profiles
```

If auth, account access, `ANTHROPIC_API_KEY`, or model availability still blocks
the planner, stop with repair steps. Do not silently downgrade or claim Opus.

Record:

- planner profile path and whether it is provider-neutral
- executor profile path and whether it uses `MiniMax-M2.7-highspeed`
- selected `model_profile` and whether it is default cost-optimized or an
  explicit user override
- requested planner model
- requested executor model
- local capacity ceiling
- MiniMax provider ceiling or `unverified-default-1`
- effective executor budget

Budget formula:

```text
effective_executor_budget = min(
  local_recommended_ceiling,
  provider_executor_ceiling,
  independent_packets,
  supervisor_review_capacity,
  verifier_capacity
)
```

## Phase 1: Research And SPEC

For file-changing work, follow the repo's normal lifecycle:

1. Taste/current-state check.
2. Metacognitive route with capacity evidence.
3. `/deepresearch` or local-only research brief.
4. Code audit before planning.
5. `/introspect pre-plan`.
6. Concrete plan.
7. Agent-Native Estimate.
8. `SPEC.md` active contract.
9. `/specqa` execution-allowed decision and `plan_mode` transition checkpoint
   before implementation packets run.

Do not skip `/workflow` discipline. `/opusminimax` wraps the workflow with a
provider split and packet contract.

## Phase 2: Executor Packetization

MiniMax only receives bounded packets. Write or request packets with:

```json
{
  "artifact_type": "opusminimax-packet",
  "run_id": "YYYYMMDD-HHMMSS-task",
  "packet_id": "P1",
  "objective": "One bounded implementation objective",
  "context_summary": "Planner-provided context, not full hidden reasoning",
  "owned_paths": ["path/or/glob"],
  "forbidden_paths": [".env", ".claude/*.local.json", "secrets/**"],
  "commands_allowed": ["bash scripts/specific-check.sh"],
  "acceptance_checks": ["observable check"],
  "risk_notes": ["what can go wrong"],
  "rollback_plan": "How to revert this packet safely",
  "expected_outputs": ["diff", "worker-result", "logs"],
  "stop_conditions": ["ambiguous ownership", "secret requested"]
}
```

Hard packet rules:

- One owner per packet.
- Clear write ownership; no overlapping files unless a sync barrier exists.
- No broad `**` ownership for implementation packets unless the packet is
  explicitly read-only.
- No credential paths in packet context.
- No benchmark gold/hidden data in executor-visible prompts.

## Phase 3: MiniMax Execution

Use the executor bridge:

```bash
bash scripts/minimax-exec.sh --packet .taste/opusminimax/{run_id}/packets/P1.json --run-dir .taste/opusminimax/{run_id}
```

The bridge validates the packet and writes a sidecar. Runtime model calls are
opt-in:

```bash
bash scripts/minimax-exec.sh --packet ... --run-dir ... --execute
```

Do not trust the executor closeout by default. Required evidence:

- diff or touched files
- commands run
- logs or summaries tied to commands
- acceptance checks
- unresolved failures
- parent verification status

## Phase 4: Claude Review And Verification

Claude/Opus reviewer duties:

- Compare executor output to `SPEC.md`.
- Verify claimed commands and changed files.
- Reject out-of-ownership changes.
- Run or inspect static gates appropriate to the change.
- Record failed verification as blocked, not positive closeout.
- Run `/introspect post-implementation`.

Final status must be one of:

- `verified`: static/runtime evidence supports the claim
- `blocked`: execution cannot be trusted yet
- `partial`: some packets accepted, others rejected
- `runtime-pending`: static contract passes, provider runtime not exercised

## Benchmark Repair Mode

Use for SWE-bench-style or Terminal-Bench-style tasks only when the user asks
for benchmark/repair mode.

Pipeline:

```text
task intake -> gold/hidden quarantine -> localization -> repro test attempt ->
MiniMax candidate patches -> validation -> Claude adversarial selection ->
prediction/export
```

Benchmark rules:

- The solver sees only visible prompt and pre-fix repo state.
- Gold patches, hidden tests, and judge-only data stay quarantined.
- Aggregate scores require per-task result artifacts.
- Static harness evals are not benchmark proof.
- Do not claim SWE-bench, Terminal-Bench, SWE-Bench Pro, or private benchmark
  strength without reproducible per-task evidence.

## Required Run Artifact

When `/opusminimax` executes or prepares a real run, produce:

```json
{
  "artifact_type": "opusminimax-run",
  "run_id": "YYYYMMDD-HHMMSS-task",
  "outer_route": "opusworkflow",
  "inner_contract": "workflow",
  "model_profile": "minimax",
  "executor_provider": "minimax",
  "planner_identity_status": "blocked",
  "executor_identity_status": "configured",
  "fallback_status": "none",
  "provider_profiles": {
    "planner": {"path": ".claude/settings.opusminimax-planner.example.json"},
    "executor": {"path": ".claude/settings.minimax-executor.example.json"}
  },
  "model_ids": {
    "planner_requested": "claude-opus-4-7",
    "executor_requested": "MiniMax-M2.7-highspeed"
  },
  "model_route": {
    "profile": "minimax",
    "planner": {"provider": "anthropic", "requested_model": "claude-opus-4-7", "identity_status": "blocked"},
    "executor": {"provider": "minimax", "requested_model": "MiniMax-M2.7-highspeed", "identity_status": "configured"},
    "fallback_policy": "fail-closed-unless-explicit"
  },
  "plan_mode": {
    "enabled": true,
    "policy": "auto",
    "checkpoint": "pre-implementation-plan-approval",
    "auto_approval": {
      "status": "auto_approved_when_gates_pass",
      "execution_allowed_after": [
        "research_brief_recorded",
        "code_audit_recorded",
        "pre_plan_introspection_pass",
        "agent_native_estimate_recorded",
        "spec_created_updated_or_reused",
        "specqa_execution_allowed"
      ]
    },
    "does_not_replace": ["SPEC.md", "/specqa", "/introspect", "/verify", "runtime_model_identity_proof"]
  },
  "capacity": {
    "local_ceiling": 10,
    "provider_ceiling": 1,
    "task_packet_count": 1,
    "safety_cap": 1,
    "effective_concurrency": 1
  },
  "packets": ["P1"],
  "verification": {"status": "runtime-pending"},
  "failures": [],
  "retries": 0,
  "final_confidence": "medium"
}
```

Validate sidecars:

```bash
bash scripts/artifact-lint.sh .taste/opusminimax/{run_id}/opusminimax-run.json
bash scripts/artifact-lint.sh .taste/opusminimax/{run_id}/packets/P1.json
```

## Anti-Patterns

- "Opus planned this" with no model identity evidence.
- Planner and executor sharing one provider profile.
- Using the full 10-lane local ceiling because it looks powerful.
- Giving MiniMax an unbounded repo-wide task.
- Calling static fixtures benchmark proof.
- Hiding runtime failures behind "ready" or "done".
- Letting executor summaries replace parent verification.
