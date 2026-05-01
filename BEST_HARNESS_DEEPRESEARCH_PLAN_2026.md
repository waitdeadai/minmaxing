# Best Possible Minmaxing Harness Plan

Date: 2026-05-01
Status: benchmark-backed execution plan, not an active implementation SPEC
Repo baseline: `d00ebc0 Add agent-native time estimation gates`
Primary goal: make the harness steer LLMs toward effective, evidence-backed,
production-grade work instead of shallow or lazy completion.
Target CLI substrate: Claude Code with MiniMax-compatible Anthropic settings.
Implementation executor for this plan: Codex as main orchestrator, using
bounded parallel agents for research, review, fixtures, and disjoint patches.

## Executive Verdict

Minmaxing is already unusually strong as a contract-first agent harness. Its
core advantages are taste-first planning, active `SPEC.md`, research gates,
hard introspection, surgical diffs, capacity-aware parallel guidance,
AgentFactory runtime contracts, and the new Agent-Native Estimate layer.

The next leap is not another skill and not a bigger orchestration diagram. The
next leap is to make the harness mechanically hostile to lazy work:

- no generic research when current facts matter
- no plan freeze without evidence
- no worker summary accepted as truth
- no "tests passed" without commands and outputs
- no positive closeout after failed verification without a fix/reverify,
  blocked outcome, or explicit operator override
- no 10-lane optimism when ownership, verification, or the supervisor is the
  bottleneck

The best possible version is an effectiveness harness first and an acceleration
harness second. Runtime governance, traces, schemas, and CI only matter if they
make shallow success harder and verified success easier.

The best possible version should combine:

- minmaxing's taste/spec/introspection operating kernel
- Claude Code skills, hooks, permissions, headless smoke, and subagent/task
  lifecycle as the actual target runtime
- Codex-style bounded parallel agents for implementing and auditing the harness
  changes, with explicit `max_threads`, `max_depth`, and worker result
  contracts
- Devin-style managed-session observability, session insights, playbooks, and
  ACU-like compute accounting
- OpenHands-style structured agent SDK patterns: delegation, metrics,
  OpenTelemetry-compatible traces, and action-boundary security analyzers
- SWE-bench/eval-inspired golden task suites, trace grading, and continuous
  evaluation

## Deepresearch Brief

### Research Questions

1. Which public harness patterns matter most for production-grade coding agents
   in 2026?
2. Which parts of minmaxing are already competitive?
3. Where is minmaxing relying on model compliance instead of mechanical
   enforcement?
4. What is the smallest roadmap that can move the harness toward top-tier
   runtime quality without bloating it into a scheduler platform?
5. How should the roadmap preserve the repo's open-core boundary and active
   `SPEC.md` lifecycle?
6. How should the plan change when the target runtime is Claude Code CLI and
   the implementation executor is Codex with parallel agents?
7. Which anti-lazy failure modes must be red fixtures before scorecards,
   schemas, traces, or dashboards can count as progress?

### Local Baseline Checked

- Git state: live `main`, aligned with `origin/main`, with this plan file
  untracked until committed.
- Latest commit: `d00ebc0 Add agent-native time estimation gates`.
- Claude Code version: `2.1.118`.
- Local capacity: `scripts/parallel-capacity.sh --json` reports 16 cores,
  32GB RAM, Codex `max_threads = 10`, recommended ceiling `10`, default
  substrate `subagents`.
- Time-estimate calibration: one workflow artifact with Agent-Native Estimate;
  actual elapsed `8.9m`; confidence notes that runtime LLM compliance is still
  only statically guarded.
- Harness tests: `bash scripts/test-harness.sh` passes `66 passed, 0 failed`.
- Runtime smoke: `bash scripts/workflow-smoke.sh` passed in this environment.
- CI state: no `.github/` workflow directory currently exists.
- Runtime enforcement state: state hooks are wired, but `block-config.sh` and
  `auto-format.sh` are not wired into `.claude/settings.json` as active
  PreToolUse/PostToolUse hooks.
- Security posture: shared project default is `bypassPermissions`; team-safe
  example exists with `acceptEdits`.
- Codex config state: `.codex/config.toml` sets `gpt-5.5`, medium reasoning,
  `agents.max_threads = 10`, and `agents.max_depth = 1`.
- Codex project agents state: `repo_explorer`, `docs_researcher`, and
  `reviewer` are read-only via their `.codex/agents/*.toml` files.
- Claude Code project agent state: no `.claude/agents/` directory is present
  today, so Claude-side parallelism should rely first on built-in subagents,
  skills, hooks, and optional experimental agent teams only when explicitly
  enabled.
- Working-state caveat: `.minimaxing/state/CURRENT.md` is stale relative to
  live git and must be treated as a continuity hint, not current truth.

### Source Ledger

| Source | Relevant benchmark pattern | Harness implication |
|---|---|---|
| OpenAI Codex subagents docs: https://developers.openai.com/codex/subagents | Codex can spawn specialized agents in parallel, handles orchestration, and has explicit `max_threads`, `max_depth`, and worker timeout controls. | Keep `main` as orchestrator; make concurrency ceilings explicit and observable. |
| OpenAI Codex subagent concepts: https://developers.openai.com/codex/concepts/subagents | Subagents reduce context pollution/rot but should start with read-heavy parallel work; write-heavy parallelism needs care. | Parallel work should default to exploration, review, tests, and disjoint ownership packets before write-heavy packets. |
| OpenAI Codex config reference: https://developers.openai.com/codex/config-reference | `agents.max_threads`, `agents.max_depth`, approval policy, app tool controls, and permission profiles are runtime controls. | Minmaxing should treat local config as a runtime contract, not just documentation. |
| OpenAI trace grading docs: https://developers.openai.com/api/docs/guides/trace-grading | Trace evals grade end-to-end decisions, tool calls, and reasoning steps for regression analysis. | Add local trace artifacts and trace-level graders before claiming harness quality improved. |
| OpenAI eval best practices: https://developers.openai.com/api/docs/guides/evaluation-best-practices | Evals should be continuous, task-specific, automated when possible, and multi-agent architecture should be driven by evals. | Add golden harness tasks and score changes before increasing orchestration complexity. |
| Claude Code subagents docs: https://code.claude.com/docs/en/sub-agents | Subagents have separate context, scoped tools, independent permissions, and preserve main context. | Project agents should stay narrow and tool-scoped; use them to keep exploration noise out of main. |
| Claude Code hooks docs: https://code.claude.com/docs/en/hooks | Hooks can block PreToolUse, inspect PostToolUse, track SubagentStart/Stop, TaskCreated, TaskCompleted, and more. | Move key gates from prose to hooks: risky commands, missing artifacts, evidence-free completion, and spec/estimate order. |
| Claude Code headless docs: https://code.claude.com/docs/en/headless | `claude -p` runs Claude Code non-interactively with CLI options and structured output, while `--bare` intentionally skips project context such as hooks, skills, plugins, MCP, memory, and `CLAUDE.md`. | Runtime smoke must run in the normal project context when testing hooks and skills; bare mode is only for deterministic isolated checks. |
| Claude Code CLI reference: https://code.claude.com/docs/en/cli-reference | CLI flags include `--agent`, `--agents`, `--allowedTools`, `--disallowedTools`, `--permission-mode`, `--output-format`, `--json-schema`, `--include-hook-events`, and worktree/session controls. | Runtime smoke should be explicit about tools, output format, permissions, max turns, and hook visibility. |
| Claude Code common workflows: https://code.claude.com/docs/en/common-workflows | Parallel Claude sessions can use Git worktrees; subagents can also use worktree isolation with `isolation: worktree`. | Parallel writes need worktree isolation or strict file ownership; one dirty shared worktree is not the default for broad write parallelism. |
| Claude Code skills docs: https://code.claude.com/docs/en/slash-commands | Skills load on demand, may be user/model invocable, and stay in context after invocation. | Keep effectiveness rules in top-level contracts and hooks; use skills for procedures, not as the only enforcement layer. |
| Claude Code permissions docs: https://code.claude.com/docs/en/permissions | Deny rules take precedence, permission modes include `acceptEdits`, `auto`, `dontAsk`, and `bypassPermissions`, and `bypassPermissions` is for isolated environments. | Preserve solo-fast mode for trusted local use but create team-safe/runtime profiles that prove secrets and risky actions are blocked. |
| Claude Code settings docs: https://code.claude.com/docs/en/settings | Project `.claude/settings.json` is team-shared configuration; project deny rules override user allows; sensitive files should be denied explicitly. | Treat `.claude/settings.json` as the target runtime contract for Claude Code, not a generic config example. |
| Claude Code agent teams docs: https://code.claude.com/docs/en/agent-teams | Agent teams are experimental, separate sessions, shared tasks/mailbox, quality hooks, and inherited permissions. | Keep agent teams opt-in/experimental; do not make them the default. Borrow task-state and quality-gate ideas. |
| Devin advanced capabilities: https://docs.devin.ai/work-with-devin/advanced-capabilities | Managed Devins run parallel isolated sessions, track ACU, can be messaged/terminated, and analyze sessions. | Add local session insights, child-run accounting, and stuck-worker controls before scaling lanes. |
| Devin Session Insights: https://docs.devin.ai/product-guides/session-insights | Session size, ACU usage, user messages, issue timelines, and feedback loops turn runs into learning data. | Minmaxing needs `.taste/metrics` and estimate-vs-actual learning beyond static artifacts. |
| OpenHands delegation docs: https://docs.openhands.dev/sdk/guides/agent-delegation | Main agent spawns named subagents, delegates tasks, waits for consolidated results, and reports errors per child. | `/parallel` should enforce named packets, result schema, and per-worker errors. |
| OpenHands parallel tool docs: https://docs.openhands.dev/sdk/guides/parallel-tool-execution | Concurrency default is sequential; higher concurrency is useful for independent work but risky for shared state. | Capacity ceilings are ceilings, not targets; concurrency needs file ownership and sync barriers. |
| OpenHands metrics docs: https://docs.openhands.dev/sdk/guides/metrics | Track token usage, cost, latency, and aggregate conversation stats. | Add local run metrics for cost/time/latency when available, even if provider fields are partial. |
| OpenHands observability docs: https://docs.openhands.dev/sdk/guides/observability | OTEL traces can capture agent steps, tool calls, LLM calls, browser sessions, and lifecycle events. | Create a local trace schema that can later export to OTEL-compatible systems. |
| OpenHands security docs: https://docs.openhands.dev/sdk/guides/security | Confirmation policies and security analyzers classify action risk before execution. | Add deterministic action-boundary guard hooks for shell/file risks, with optional LLM reviewer later. |
| SWE-bench Verified: https://www.swebench.com/verified.html | Human-validated tasks and broad leaderboard scaffolds distinguish model quality from harness quality. | Use benchmark-style golden tasks, not just docs smoke tests. |
| OpenAI SWE-bench Verified post: https://openai.com/index/introducing-swe-bench-verified/ | Reliable software-agent evals need clear problem statements, valid tests, and robust environments. | Harness eval tasks must be human-clear, reproducible, and environment-checked. |
| OpenAI SWE-bench Verified retirement analysis: https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/ | Even validated coding benchmarks can become stale, contaminated, or misaligned with correct behavior. | Use local golden tasks as regression tools for harness behavior, not as absolute claims of agent capability. Refresh them as the harness matures. |

### Conflicting Evidence and Judgment

- More agents can increase speed, but Codex, Claude, and OpenHands all warn
  directly or indirectly about token/cost, coordination overhead, shared-state
  conflicts, and context handoff risk. Therefore the roadmap keeps parallelism
  capacity-aware and eval-driven, not lane-maximal.
- Agent teams are powerful for direct teammate communication, but Claude marks
  them experimental and highlights limitations. Therefore the roadmap keeps
  agent teams behind explicit opt-in and uses subagents as the default.
- Static smoke tests are cheap and valuable, but trace/eval docs point toward
  run-level grading. Therefore the roadmap preserves smoke tests while adding
  runtime and trace evaluation rather than replacing one with the other.
- Claude Code hooks are the right enforcement point for the target CLI, but
  Codex is the executor for this plan. Therefore the first slice must create
  both Claude runtime hook evidence and a Codex execution artifact so neither
  side is hand-waved.

## Effectiveness Definition

For this repo, effective means:

1. The final behavior matches the user's real goal, not the easiest literal
   interpretation.
2. Claims are backed by source reads, command evidence, or inspected artifacts.
3. Plans and estimates are grounded in the task DAG, current capacity, and
   verification gates.
4. Workers return bounded evidence; the main agent verifies claims before
   accepting them.
5. Failed verification creates a blocking state until fixed, downgraded, or
   explicitly overridden.
6. The harness rewards smallest sufficient production-grade changes, not broad
   refactors or impressive-looking scaffolding.

Anti-lazy behavior is not a vibe. It must be visible in fixtures and runtime
events. The first production slice must prove the harness rejects:

- evidence-free closeout
- human-time-only estimates
- fake linear parallel scaling
- "tests passed" without command evidence
- worker completion without owner, touched files, commands, and verification
- failed verification followed by positive closeout
- fake or empty source ledgers
- shallow code audit that cites no files

## Current Strengths

1. Taste/kernel model is coherent: `taste.md` and `taste.vision` are treated as
   operating contracts, not decorative docs.
2. `SPEC.md` lifecycle is strong: active root spec plus archived history under
   `.taste/specs/`.
3. `/workflow` is the right center of gravity: research, audit, plan, estimate,
   spec, implement, verify, closeout.
4. `/introspect` is a hard gate and already catches planning, verification,
   estimation, and changed-line trace risks.
5. `/parallel` has the right conceptual stance: main stays orchestrator,
   packet ownership is explicit, agent teams are experimental.
6. AgentFactory already models runtime contracts, capability stacks, kill
   switches, target-runtime capacity, audit evidence, and verifier metadata.
7. The harness now has Agent-Native Estimate fields and a calibration script.
8. Memory is health-checkable and currently reports healthy on this machine.
9. Claude Code is already the real target surface: `.claude/settings.json`
   configures MiniMax-compatible Anthropic variables, permissions, and state
   lifecycle hooks.
10. Codex is already a good implementation orchestrator: `.codex/config.toml`
    sets `gpt-5.5`, medium reasoning, 10 max threads, depth 1, and the
    read-only `repo_explorer`, `docs_researcher`, and `reviewer` roles.

## Core Weaknesses To Fix

1. Anti-lazy enforcement is still too implicit. Existing contracts say
   research, audit, verification, and closeout must be evidence-backed, but the
   plan must make shallow work a scored failure mode from M0.
2. Runtime enforcement is still too doc/static. Hooks exist, but key
   PreToolUse/PostToolUse/Subagent/Task/Stop action gates are not wired or
   proven by event fixtures.
3. The first plan was too generic about the runtime substrate. It cited Claude,
   Codex, Devin, and OpenHands patterns, but did not bind implementation to
   Claude Code's actual settings, hooks, skills, subagents, worktrees, and
   headless smoke behavior.
4. Codex execution evidence is missing. If Codex is going to implement this
   with parallel agents, the plan needs a Codex run artifact that records
   parent/worker packets, effective lanes, permission inheritance, and
   verification of worker claims.
5. CI is missing. Local verification passes, but no push-time or scheduled
   regression gate exists in the repo.
6. Calibration and observability are early. There is one estimate artifact, no
   trend analysis, no session-size classification, and no trace ledger.
7. Artifact validation is mostly Markdown/string based. The harness needs
   schema sidecars, but only where fixtures consume them; otherwise schemas can
   become paperwork.
8. Security defaults are optimized for a trusted solo operator. The public
   harness needs a first-class team-safe runtime profile and negative tests
   proving risky actions are blocked.
9. Parallel work needs real worker return contracts and lifecycle evidence, not
   prose summaries.
10. Evals are not first-class. There are smoke tests, but not a golden task
    suite that measures harness behavior across changes.

## North Star Architecture

```text
Taste Kernel
  -> Research and Intent Ledger
  -> Anti-Lazy Red Fixtures
  -> Active SPEC Contract
  -> Agent-Native Estimate
  -> Claude Runtime Gate Layer
  -> Codex Execution Contract
  -> Execution DAG
  -> Worker Result Schemas
  -> Failed Verification Blocking State
  -> Trace and Metrics Ledger
  -> Independent Verification
  -> Eval/Benchmark Score
  -> Calibration and Memory Update
```

The harness should make every important claim answerable from durable evidence:

- What did the user ask?
- What facts were researched and cited?
- What was the plan?
- What was estimated?
- Which gates allowed execution?
- Which tools ran?
- Which files changed?
- Which worker owned each change?
- Which tests or inspections proved success?
- Which verifier accepted it?
- How long did it actually take?
- What did this run teach the harness?

## Claude Code Target Runtime

The harness is Claude Code first. The practical target is not a theoretical
agent SDK; it is:

- `CLAUDE.md` and `.claude/rules/*.md` as always-on project memory and rules
- `.claude/skills/*/SKILL.md` as slash-command workflows
- `.claude/settings.json` as the shared project runtime contract
- `.claude/settings.local.json` as local-only secrets/preferences
- Claude hooks as deterministic runtime gates
- Claude subagents as bounded worker contexts
- Git worktrees for parallel write isolation when shared dirty state would be
  risky
- agent teams only when explicitly enabled with
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `claude -p --output-format json` or `stream-json` for bounded smoke and CI
  style checks when credentials are available

Important target-runtime rules:

- Do not use `--bare` for runtime governance smoke because bare mode skips
  hooks, skills, plugins, MCP, memory, and `CLAUDE.md`.
- Do not claim sandbox/container isolation unless a run actually used a
  sandbox, container, or worktree.
- Do not treat Codex `agents.max_threads` as the Claude runtime limit. It is
  one capacity input for Codex-assisted implementation, not proof that Claude
  can safely run 10 write lanes in one worktree.
- Do not make project `.claude/agents/` a blocker for the first slice. Built-in
  Claude subagents, hooks, skills, and worktrees are enough to enforce the
  first production gates.

## Codex Implementation Runtime

This plan should be implemented by Codex as main orchestrator with bounded
parallel agents:

- `repo_explorer`: read-only repo evidence and file-path mapping
- `docs_researcher`: current official docs and benchmark source verification
- `reviewer`: adversarial plan/code review
- optional `worker`: disjoint code edits only after `SPEC.md` and ownership are
  frozen

Codex is not the product runtime. Codex is the executor building and reviewing
the Claude Code harness. Therefore every implementation slice must distinguish:

- `target_runtime = Claude Code`
- `implementation_executor = Codex`
- `execution_topology = local main + bounded Codex subagents`
- `claude_runtime_evidence = hook/settings/headless smoke output`
- `codex_execution_evidence = run artifact and worker result summaries`

The first implementation slice must create a lightweight Codex run artifact
under `.taste/codex-runs/{run_id}/` or a root-equivalent workflow artifact that
records packet DAG, requested agents, effective lanes, permissions/sandbox
notes, and parent verification of worker claims. It can start as a simple JSON
or Markdown+JSON pair, but it must be machine-checkable enough for a smoke
fixture.

## Target Maturity Model

| Level | Name | Definition | Current state |
|---|---|---|---|
| L0 | Prompt-only | Instructions ask the model to behave. | Surpassed. |
| L1 | Contract harness | Skills/rules/specs/smokes encode behavior. | Current strong baseline. |
| L2 | Runtime-gated harness | Hooks and scripts block unsafe or incomplete actions. | Next milestone. |
| L3 | Trace/eval harness | Runs produce structured traces, metrics, and golden-task scores. | Planned. |
| L4 | Calibrated orchestrator | Estimates, lane choices, and verification budgets improve from real run history. | Planned. |
| L5 | Managed agent OS | Local and remote lanes, team-safe profiles, CI, dashboards, and open-core packaging are coherent. | Strategic target. |

## Roadmap

### M0: Anti-Lazy Harness Scorecard And Red Fixtures

Goal: create an objective scorecard that starts by measuring whether the
harness rejects shallow completion, not whether the docs look complete.

Deliverables:

- `docs/harness-scorecard.md` or root `HARNESS_SCORECARD.md`
- `scripts/harness-scorecard.sh`
- Score categories: contracts, runtime hooks, permissions, parallel readiness,
  traceability, eval coverage, calibration, memory, CI, open-core safety,
  shortcut resistance, research depth quality, audit depth quality,
  verification depth quality, worker claim verification, and lazy closeout
  resistance
- Baseline JSON under `.taste/metrics/harness-scorecard.json`
- Red/green fixtures for:
  - evidence-free closeout
  - human-equivalent-only estimate
  - fake "10 agents means 10x faster" scaling
  - worker completion without owner/files/commands/evidence
  - failed verification followed by positive closeout
  - fake or empty source ledger
  - shallow code audit with no cited files

Acceptance gates:

- Scorecard runs without network or secrets.
- It records current commit, test status, capacity profile, memory health, and
  estimate history count.
- It clearly separates static contract coverage from runtime proof.
- It is invalid if it reports maturity without red-fixture results.
- It reports `red_fixture_expected_failure` until M1/M1.5/M2 controls make the
  fixture pass for the right reason.
- It does not count a heading or schema field as effective unless evidence is
  present behind it.

### M0.5: Codex-Orchestrated Execution Contract

Goal: make the implementation path honest: Codex will execute this roadmap with
bounded parallel agents, while Claude Code remains the target runtime being
improved.

Deliverables:

- `.taste/codex-runs/{run_id}/packet-dag.json` or equivalent first-run
  artifact
- `.taste/codex-runs/{run_id}/worker-results/*.json` for future worker output,
  or a documented minimal placeholder if the first slice stays single-lane
- `docs/codex-execution-contract.md` or a section in the scorecard docs
- `scripts/codex-run-smoke.sh`

Required fields:

- `target_runtime`: `claude-code`
- `implementation_executor`: `codex`
- `requested_agents`
- `effective_lanes`
- `capacity_profile`
- `codex_parent_permission_profile`
- `child_sandbox_policy`
- `approval_inheritance_risk`
- `packet_ownership`
- `worker_result_schema_version`
- `parent_verified_worker_claims`

Acceptance gates:

- Codex run smoke validates the artifact without network or secrets.
- It proves `repo_explorer`, `docs_researcher`, and `reviewer` are read-only
  when used for evidence gathering.
- It warns or blocks when the parent executor is in a broad/no-sandbox mode and
  write-capable workers are proposed.
- It records that Codex `max_threads` is a ceiling, not a target.
- It provides a copy-pasteable execution packet plan for the next slice.

### M1: Runtime Governance Hooks

Goal: move the highest-value anti-lazy and safety gates from prose into
Claude Code action-boundary checks.

Deliverables:

- Wire existing `block-config.sh` only if it is upgraded into the new
  governance model.
- Keep `auto-format.sh` non-authoritative unless formatter behavior is proven
  safe; formatting convenience must not hide verification failures.
- Add `.claude/hooks/govern-tool-use.sh`.
- Add `.claude/hooks/govern-stop.sh`.
- Add `.claude/hooks/govern-task-completed.sh` for agent-team/task-compatible
  contexts where the event is available.
- Add `.claude/hooks/govern-subagent-stop.sh` when a stable Claude hook payload
  is available in fixtures.
- Add `scripts/hook-smoke.sh`.
- Record hook decisions into `.taste/runtime-events/*.jsonl`.

Required gates:

- Block reading `.env`, `.env.*`, `secrets/**`, and local settings files unless
  already denied by platform permissions.
- Block destructive shell patterns unless explicitly allowed.
- Warn or block direct writes to protected config without active SPEC evidence.
- Block closeout language when `SPEC.md`, `Agent-Native Estimate`, or
  verification evidence is missing for non-trivial work.
- Block positive closeout after failed verification unless a later passing
  verification references the failure, the outcome is explicitly blocked, or an
  operator override is recorded.
- Block parallel task completion without a minimal Worker Result Schema.
- Warn on shallow source ledgers and code audits that cite no files/sources.

Acceptance gates:

- `scripts/hook-smoke.sh` feeds representative Claude hook JSON payloads into
  every governance hook and asserts exact exit behavior.
- Negative fixtures prove exit `2` or explicit deny JSON for destructive Bash,
  secret read, protected config write without active SPEC evidence,
  evidence-free closeout, failed-verification positive closeout, and worker
  completion without evidence.
- Positive fixtures prove normal safe reads/edits and blocked outcomes are not
  blocked.
- `.claude/settings.json` and `.claude/settings.team-safe.example.json` include
  active hook mappings where appropriate.
- Existing state lifecycle hooks remain intact.
- Runtime events are valid JSONL and redact sensitive paths/content.
- `bash scripts/test-harness.sh` includes hook smoke.
- Runtime smoke still passes.
- M1 is not accepted if the diff only adds docs or static grep checks without
  exercising hook exit behavior.

### M1.5: Minimal Parallel Claim Validator

Goal: make worker claims machine-checkable before full schema/tracing work.

Deliverables:

- `scripts/parallel-plan-lint.sh`
- `schemas/worker-result.schema.json` or an inline minimal schema consumed by
  the linter
- fixture packets under a dedicated fixture path

Required rejection fixtures:

- missing packet owner
- missing owned files
- touched file outside ownership
- two packets claiming the same file without a merge barrier
- missing commands run
- missing verification evidence
- worker summary accepted without parent verification

Acceptance gates:

- `bash scripts/parallel-plan-lint.sh --fixtures` passes.
- `bash scripts/parallel-smoke.sh` references the validator.
- `/parallel` and `/workflow` are updated so worker summaries are claims until
  the parent verifies artifacts or commands.
- Full aggregation tooling is explicitly deferred until M5.

### M2: Schema Sidecars for Artifacts

Goal: keep Markdown for humans but add only the machine-readable contracts that
anti-lazy gates and fixtures consume.

Deliverables:

- `schemas/agent-native-estimate.schema.json`
- `schemas/verification-result.schema.json`
- `schemas/worker-result.schema.json`
- `scripts/artifact-lint.sh`
- Later, after eval demand proves value: `workflow-run`, `spec`, and full
  `parallel-packet` schemas.

Required sidecars:

- `.taste/verification/*.json`
- `.taste/parallel/*.json`
- `.taste/estimates/*.json`

Acceptance gates:

- Existing Markdown artifacts can be summarized into JSON with best-effort
  extraction.
- New artifacts must pass schema validation.
- Artifact lint rejects human-equivalent-only estimates, missing confidence,
  missing critical path, missing verification metadata, and unowned worker
  packet changes.
- Artifact lint rejects `tests_passed` claims with no command evidence.
- Artifact lint rejects failed verification followed by positive closeout
  unless a valid transition is recorded.
- No new schema category is accepted unless an M0, M1, M1.5, or M4 fixture
  consumes it.

### M3: Trace, Metrics, and Session Insights

Goal: make every run inspectable like a small local Devin/OpenHands session,
after the first anti-lazy gates already prove behavior changed.

Deliverables:

- `.taste/metrics/runs.jsonl`
- `.taste/traces/{run_id}.jsonl`
- `scripts/run-metrics.sh`
- `scripts/session-insights.sh`
- `scripts/estimate-history.sh` upgrade to compute error bands and buckets

Defer from earlier slices:

- broad session-size buckets
- cost accounting when provider data is unavailable
- full trace taxonomy for every artifact
- estimate error bands beyond `insufficient_data` until enough real runs exist

Trace event types:

- `session.started`
- `research.source_reviewed`
- `spec.frozen`
- `estimate.recorded`
- `tool.executed`
- `file.changed`
- `worker.started`
- `worker.completed`
- `verification.failed`
- `verification.passed`
- `human.blocked`
- `run.closed`

Session insight metrics:

- elapsed wall-clock
- active agent-hours when known
- effective lanes
- planned vs actual wall-clock
- verification failure count
- rework loops
- human blocker minutes
- prompt/user message count when available
- tool-call count when available
- cost/tokens when provider data is available
- session size: XS/S/M/L/XL, using local thresholds

Acceptance gates:

- A run can be reconstructed from local artifacts without reading chat history.
- `session-insights.sh` flags unhealthy runs: high rework, missing verification,
  large estimate error, repeated failed hooks, or evidence-free closeout.
- Estimate calibration never invents data; it reports `insufficient_data` until
  enough real runs exist.

### M4: Eval and Benchmark Pack

Goal: judge harness behavior with repeatable tasks, not vibes.

Deliverables:

- `evals/harness/tasks/*.yaml`
- `evals/harness/golden/*.json`
- `scripts/harness-eval.sh`
- `scripts/harness-eval-report.sh`

Initial golden tasks:

1. Tiny `/workflow` file creation with required SPEC and estimate.
2. Bad estimate rejection: human-equivalent-only.
3. Bad parallel claim rejection: "10 agents means 10x faster."
4. Protected config write attempt.
5. Secret read attempt.
6. Missing verification closeout.
7. Worker packet without owner.
8. Worker packet touching another packet's file.
9. Failed test must block closeout.
10. Active `SPEC.md` archive lifecycle.
11. Local-only research justification for trivial work.
12. External research source ledger for current-fact work.
13. AgentFactory manifest missing kill switch.
14. AgentFactory active registry with `operator_exception`.
15. Memory degraded mode must be reported, not hidden.
16. Fake source ledger must fail when citations were not read.
17. Shallow code audit must fail when no files/symbols are cited.
18. "Tests passed" claim must fail without command evidence.
19. Worker summary must fail if parent verification is missing.
20. Failed verification followed by positive closeout must fail unless fixed,
    blocked, or overridden.
21. Claude runtime enforcement claim must fail if hook mappings are absent.
22. Codex parallel execution claim must fail if no Codex run artifact exists.

Scoring dimensions:

- contract completeness
- runtime enforcement
- evidence quality
- shortcut resistance
- research depth quality
- audit depth quality
- verification depth quality
- overclaim resistance
- security boundary
- parallel correctness
- estimate quality
- user-facing clarity

Acceptance gates:

- Eval report has pass/fail counts and per-task failure reasons.
- CI can run offline/static evals without credentials.
- Authenticated runtime evals are optional but first-class.
- Adding multi-agent complexity requires eval improvement or a documented
  non-score reason.

### M5: Parallel Orchestration Hardening

Goal: make `/parallel` operationally real, not just well described.

Prerequisite: M1.5 has already landed the minimal worker claim validator. M5 is
the full aggregation and lifecycle layer, not the first time worker claims
become checkable.

Deliverables:

- `scripts/parallel-plan-lint.sh`
- `scripts/parallel-aggregate.sh`
- `.taste/parallel/{run_id}/packet-dag.json`
- `.taste/parallel/{run_id}/ownership.json`
- `.taste/parallel/{run_id}/worker-results/*.json`
- updated `/parallel`, `/workflow`, `/verify`, and `/introspect` contracts

Required behavior:

- Compute effective lanes from packet DAG, ownership, host capacity, substrate,
  CI bottlenecks, supervisor/verifier capacity, and sync barriers.
- Workers must return structured result JSON:
  - packet id
  - owned files
  - files touched
  - commands run
  - tests run
  - evidence
  - unresolved risks
  - changed-line trace
  - handoff notes
- Aggregator rejects cross-owned edits unless explicitly approved.
- Verification treats worker summaries as claims until evidence is checked.

Acceptance gates:

- Parallel smoke includes positive and negative packet fixtures.
- Subagent use remains explicit and bounded.
- Agent teams remain opt-in experimental.
- Adding lanes beyond the bottleneck shows no false speedup claim.

### M6: Security and Permission Profiles

Goal: support both your trusted-local speed loop and a shareable team-safe
harness without confusing the two.

Deliverables:

- `.claude/settings.solo-fast.example.json`
- `.claude/settings.team-safe.example.json` promoted in docs
- `.claude/rules/security.rules.md`
- `scripts/security-smoke.sh`
- `SECURITY.md` update with runtime policy matrix

Profiles:

- `solo-fast`: trusted local, fewer prompts, fast iteration, still blocks
  secrets and catastrophic commands.
- `team-safe`: acceptEdits, tighter Bash allowlist, no broad web side effects,
  hook checks enabled.
- `ci-static`: no external network, no secrets, static lint/eval only.
- `ci-runtime`: authenticated, isolated temp workspace, runtime smoke/evals.

Acceptance gates:

- Tests prove both solo-fast and team-safe JSON are valid.
- Security smoke proves negative fixtures are blocked.
- Docs clearly say that bypass mode is not the recommended team default.

### M7: CI and Release Governance

Goal: make every push prove the public harness contract.

Deliverables:

- `.github/workflows/harness-static.yml`
- `.github/workflows/harness-runtime.yml` for manual or scheduled authenticated
  runs
- release checklist in `CONTRIBUTING.md`
- `scripts/release-check.sh`

CI lanes:

- Static lane:
  - `bash -n scripts/*.sh`
  - `bash scripts/estimate-smoke.sh`
  - `bash scripts/parallel-smoke.sh`
  - `bash scripts/agentfactory-smoke.sh`
  - `bash scripts/digestflow-smoke.sh`
  - `bash scripts/hook-smoke.sh`
  - `bash scripts/artifact-lint.sh --fixtures`
  - `bash scripts/harness-eval.sh --static`
  - `bash scripts/test-harness.sh`
  - `git diff --check`
- Runtime lane:
  - `RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh`
  - runtime eval subset in temp workspaces
  - no real secrets beyond a dedicated test token/profile

Acceptance gates:

- Public PRs can run static checks without private credentials.
- Runtime checks never expose secrets in logs.
- Failing smoke/eval blocks release.

### M8: Memory and Learning Loop

Goal: make memory a measured subsystem, not a trust assumption.

Deliverables:

- `scripts/memory-eval.sh`
- memory freshness report in `start-session.sh`
- memory event traces for decisions/patterns/errors
- run-to-memory promotion policy

Required behavior:

- If memory is degraded, the workflow says so and falls back to local truth
  surfaces.
- Memory recall quality is evaled with a small set of known prior decisions.
- Important run insights become candidate memory entries only after verification.
- No sensitive customer memory seeds or private commercial playbooks enter the
  public open-core repo.

Acceptance gates:

- Memory health reports `healthy`, `degraded`, or `disabled`.
- Memory eval catches missing or stale critical repo facts.
- Workflow does not claim memory captured everything unless evidence exists.

### M9: Documentation, Distribution, and Open-Core Boundary

Goal: make the public harness understandable, installable, and safe to extend.

Deliverables:

- README "runtime governance" section
- docs-style quickstart for solo-fast vs team-safe vs CI
- public examples using dummy repos only
- `COMMERCIAL.md` boundary refresh
- plugin/installer guidance for Codex/Claude users

Acceptance gates:

- A new user can run static smoke without secrets.
- A trusted operator can enable runtime smoke with local credentials.
- Private REVCLI/Hermes runtime code remains out of the public repo.
- Docs do not overclaim that the harness is autonomous without verification.

## Implementation Order

The roadmap should land in small, verifiable slices:

1. M0 anti-lazy scorecard and red fixtures.
2. M0.5 Codex execution contract and run artifact smoke.
3. M1 smallest Claude Code runtime hook vertical slice that actually blocks.
4. M1.5 minimal parallel worker-claim validator.
5. M2 minimal schema sidecars and artifact lint consumed by fixtures.
6. M4 static harness eval pack, pulled earlier than broad metrics.
7. M3 run metrics and session insights after behavior gates exist.
8. M6 security profiles, before broader runtime CI.
9. M7 CI static lane.
10. M5 full parallel hardening after minimal validator, schemas, and evals.
11. M8 memory evals.
12. M9 docs/distribution pass.

This order intentionally builds anti-lazy proof before adding more autonomy or
observability. If a proposed schema, trace, dashboard, or lane does not make a
red fixture fail/pass more honestly, defer it.

## Non-Goals

- Do not replace `SPEC.md` as the active root contract.
- Do not build a scheduler daemon before hooks, traces, evals, and CI exist.
- Do not make Claude agent teams the default.
- Do not make 10 lanes the default just because capacity allows 10.
- Do not design around Codex `max_threads` as if it were the Claude Code
  runtime concurrency model.
- Do not claim Claude Code hook enforcement unless `.claude/settings.json` maps
  the hook and `scripts/hook-smoke.sh` proves the event behavior.
- Do not claim Codex parallel execution unless a Codex run artifact records the
  packets, agents, and parent verification.
- Do not move private REVCLI runtime code, customer agents, real audit logs, or
  commercial playbooks into the public repo.
- Do not treat Markdown docs as sufficient proof once runtime gates exist.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock for implementing the roadmap.
- Execution topology: Codex main orchestrator + bounded Codex subagents for
  implementation/review; target runtime is Claude Code; agent-teams-experimental
  only for future opt-in testing.
- Capacity evidence: `scripts/parallel-capacity.sh --json`; Codex
  `max_threads = 10`; current recommended ceiling `10`; Claude Code
  `2.1.118`; agent teams currently unavailable in capacity profile.
- Effective lanes:
  - Plan artifact only: 1 lane, completed in this pass.
  - First execution slice, M0-M1.5: 3-4 effective lanes for scorecard,
    Codex run artifact, hook fixtures, and minimal parallel validator, with
    main retaining `SPEC.md`, `.claude/settings.json`, and integration.
  - M2-M4 implementation: 2-4 effective lanes after hook and worker fixtures
    exist.
  - M3-M7 implementation: 3-5 effective lanes after schema, hook, and eval
    surfaces exist.
  - M8-M9: 1-3 lanes because memory/docs/open-core decisions are supervisory.
- Critical path:
  `anti-lazy red fixtures -> Codex execution contract -> Claude hook gate -> minimal worker validator -> minimal schemas -> eval pack -> metrics/insights -> security profiles -> CI -> full parallel hardening -> memory eval -> docs`
- Agent wall-clock:
  - M0-M1.5 first production slice: optimistic 5h / likely 9h /
    pessimistic 16h.
  - M0-M2 production slice: optimistic 7h / likely 14h / pessimistic 24h.
  - M0-M7 strong harness slice: optimistic 2 days / likely 4 days /
    pessimistic 7 days, assuming runtime credentials and CI token setup are
    available.
  - Full L5 managed-agent-OS maturity: optimistic 1.5 weeks / likely 3 weeks /
    pessimistic 5+ weeks, because real calibration needs repeated runs, CI
    history, and operator feedback.
- Agent-hours:
  - M0-M1.5: 14-34 active agent-hours.
  - M0-M2: 24-48 active agent-hours.
  - M0-M7: 45-90 active agent-hours.
  - L5 maturity: 120-250+ active agent-hours across implementation,
    verification, eval expansion, docs, and calibration.
- Human touch time:
  - M0-M1.5: 30-75 minutes for hook strictness and Codex/Claude runtime
    boundary review.
  - M0-M2: 60-120 minutes for approval of hook strictness and public defaults.
  - M0-M7: 2-5 hours for CI credentials, policy choices, review, and release.
  - L5 maturity: recurring review of eval failures, memory promotions, and
    runtime safety policies.
- Calendar blockers:
  CI availability, authenticated Claude/MiniMax test settings, GitHub Actions
  secrets, runtime smoke credentials, provider rate limits, and human decisions
  about default permission posture.
- Confidence: medium. The implementation path is clear, but runtime hook
  behavior, Claude credentials, provider auth, and real eval signal need
  empirical proof.
- Human-equivalent baseline: optional comparison only; roughly several
  engineer-weeks for a conventional team because the work spans harness design,
  test infrastructure, security policy, observability, docs, and calibration.

## Acceptance Definition For "Best Possible Harness"

The harness is not "best possible" when docs sound impressive. It is best
possible when it can repeatedly prove these outcomes:

- A new non-trivial task cannot freeze a plan without research status,
  Agent-Native Estimate, active SPEC, and verification plan.
- A risky tool action is blocked or escalated before execution.
- A closeout without evidence is rejected.
- A fake source ledger or shallow audit is rejected instead of counted as
  research.
- A `tests passed` claim without command evidence is rejected.
- A failed verification command creates a blocking state that prevents positive
  closeout until a later passing verification references the same failure, the
  outcome is marked blocked, or an explicit operator override is recorded.
- A parallel packet cannot claim completion without owned files, commands,
  evidence, and changed-line trace.
- A worker result is treated as a claim until the parent verifies artifacts or
  commands.
- A run can be reconstructed from local artifacts without chat history.
- A run receives a harness eval score.
- Estimate accuracy improves from real history, or reports insufficient data.
- CI catches static contract drift.
- Runtime smoke catches model-compliance drift.
- Claude Code enforcement claims cite hook mappings and hook-smoke evidence.
- Codex parallel execution claims cite a Codex run artifact.
- Team-safe usage is documented and testable.
- Private/commercial material stays outside the public repo.

## First Execution Slice Packet Plan

Use 3-4 effective lanes, not 10. The hardware/Codex ceiling is 10, but the
first slice touches shared authority surfaces and should optimize for correctness
over lane count.

| Packet | Owner | Scope | Owns | Must not touch | Can run with |
|---|---|---|---|---|---|
| P0-main | Codex main | SPEC lifecycle, architecture, settings decisions, aggregation, final verification | `SPEC.md`, workflow artifact, final `.claude/settings.json` decision, final `scripts/test-harness.sh` integration | none | all |
| P1-scorecard | worker | M0 anti-lazy scorecard and red fixtures | `scripts/harness-scorecard.sh`, scorecard docs, fixture definitions | hooks, settings, schemas, test harness | P2, P3 |
| P2-hooks | worker | M1 governance hook scripts and event format | `.claude/hooks/govern-*.sh`, runtime-event JSONL examples | settings final wiring, test harness, schemas | P1, P3 |
| P3-codex-contract | worker | M0.5 Codex run artifact and smoke | `scripts/codex-run-smoke.sh`, Codex execution contract docs/fixtures | hooks, settings, test harness | P1, P2 |
| P4-parallel-validator | worker | M1.5 worker claim validation | `scripts/parallel-plan-lint.sh`, minimal worker fixtures/schema | hooks, settings, scorecard | after P1/P2 enough to align fixtures |
| P5-integration | main or one worker | Contract and harness integration | targeted `/workflow`, `/parallel`, `/introspect`, `/verify`, `CLAUDE.md`, `AGENTS.md`, `scripts/test-harness.sh` edits | broad schema/CI/metrics work | after P1-P4 |

Sync barriers:

- B1: after P1-P3, main reviews fixture vocabulary, hook strictness, and Codex
  artifact shape.
- B2: after P4, main verifies worker claim validator before integrating with
  `/parallel`.
- B3: final integration, full local verification, `/introspect`, and closeout.

Verification for the first slice:

- `git status --short`
- archive or reuse active `SPEC.md` before replacing it
- `bash scripts/parallel-capacity.sh --json`
- `python3 -m json.tool .claude/settings.json`
- `bash -n` for every changed shell script
- `bash scripts/harness-scorecard.sh --json`
- `bash scripts/codex-run-smoke.sh`
- `bash scripts/hook-smoke.sh`
- `bash scripts/parallel-plan-lint.sh --fixtures`
- `bash scripts/estimate-smoke.sh`
- `bash scripts/parallel-smoke.sh`
- `bash scripts/test-harness.sh`
- `git diff --check`
- `RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh` only when
  credentials/settings are available and safe to use

## Immediate Next Workflow Prompt

Use this when ready to implement the first slice:

```text
/workflow Implement the first execution slice from BEST_HARNESS_DEEPRESEARCH_PLAN_2026.md: M0 + M0.5 + the smallest M1 vertical slice + M1.5 minimal parallel claim validator. Goal: make minmaxing effectiveness-first and anti-lazy, with Claude Code as the target runtime and Codex as the implementation executor. Do not replace the active SPEC until you have archived or reused it according to the existing SPEC lifecycle. Before writing SPEC.md, include an Agent-Native Estimate based on scripts/parallel-capacity.sh --json and state the effective lanes.

Use bounded parallel agents only for disjoint packets: scorecard/red fixtures, governance hook scripts, Codex execution contract, and minimal worker-claim validator. Main owns SPEC.md, final .claude/settings.json decisions, integration, aggregation, and verification. The slice is accepted only if at least one real anti-lazy gate is active in Claude settings and proven by hook fixtures: evidence-free closeout must be blocked, destructive Bash must be blocked, failed-verification positive closeout must be blocked, and safe edit/read fixtures must still pass. Also produce a Codex run artifact showing target_runtime=claude-code, implementation_executor=codex, requested agents, effective lanes, permission/sandbox notes, and parent verification of worker claims.

Keep the diff surgical. Do not implement full broad schemas, CI, M3 metrics/session insights, or the full M4 eval pack in this slice. Verification must include git status, bash scripts/parallel-capacity.sh --json, python3 -m json.tool .claude/settings.json, bash -n for changed shell scripts, bash scripts/harness-scorecard.sh --json, bash scripts/codex-run-smoke.sh, bash scripts/hook-smoke.sh, bash scripts/parallel-plan-lint.sh --fixtures, bash scripts/estimate-smoke.sh, bash scripts/parallel-smoke.sh, bash scripts/test-harness.sh, git diff --check, and RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh only if credentials/settings are available and safe.
```

## Plan Maintenance

After each milestone:

1. Archive or update the active `SPEC.md` using the existing lifecycle.
2. Append actual run metrics to `.taste/metrics/runs.jsonl`.
3. Update the scorecard.
4. Promote only verified learnings into memory.
5. Re-rank the remaining roadmap based on actual failures, not initial theory.
