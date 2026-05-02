---
name: workflow
description: Run the full minmaxing workflow end to end for one request. Use when the user wants planning, implementation, verification, and closeout to happen automatically in one command.
argument-hint: [task]
disable-model-invocation: true
---

# /workflow

Run the full workflow for:

$ARGUMENTS

This command is the end-to-end executor.

`/digestflow` is a sibling route that reuses this same inline lifecycle after an external report-intake prelude. Normal `/workflow` behavior stays unchanged when no external research reports are supplied.

## Non-Negotiable Contract

- Finish the task in this command whenever it is feasible.
- For file-changing work, follow this order: deep research -> code audit -> plan -> `SPEC.md` -> execute -> verify.
- Do efficacy-first deep research for every task before planning or execution.
- Audit the current codebase before planning or writing `SPEC.md`.
- Run hard-gate introspection after code audit and before freezing the plan.
- Synthesize a concrete plan before writing `SPEC.md`.
- Record an `Agent-Native Estimate` before writing, replacing, or reusing
  `SPEC.md`. The estimate must be agent-native wall-clock by default, not a
  bare human-equivalent calendar estimate.
- Run hard-gate introspection after implementation and before closeout.
- Treat worker or subagent summaries as claims until the parent workflow
  verifies them with command evidence. For harness-governance changes, run the
  effectiveness smokes that apply: `scripts/harness-scorecard.sh --json`,
  `scripts/hook-smoke.sh`, `scripts/codex-run-smoke.sh`, and
  `scripts/parallel-plan-lint.sh --fixtures`.
- When a workflow uses `/parallel` run artifacts, aggregate
  `.taste/parallel/{run_id}/packet-dag.json`, `ownership.json`, and
  `worker-results/*.json` with `scripts/parallel-aggregate.sh` before treating
  worker outputs as accepted evidence.
- Keep implementation surgical: smallest sufficient implementation, no speculative abstractions, no drive-by refactors, and a changed-line trace back to `SPEC.md`.
- Do not stop after planning.
- Do not tell the user to manually run `/autoplan`, `/parallel`, `/sprint`, `/verify`, or `/ship`.
- Do not rely on nested custom-skill chaining as the primary execution path.
- Keep plain `/workflow` autonomous. Do not insert a mandatory visualization
  approval pause into this command. When the user explicitly wants to see and
  approve the intended product or operator experience before implementation,
  route that request to `/visualizeworkflow` instead.

Reason:
In real Claude Code sessions, nested custom skills may complete their own turn and return control to the user before the rest of the chain runs. For `/workflow`, execute the phases inline with Claude Code tools so the full flow actually completes.

You may still use built-in Claude Code tools, shell commands, subagents, and optional specialist skills as reference material when useful, but `/workflow` itself owns the whole lifecycle.

No shortcut exceptions for file-changing tasks:
- Do not say `Research: skipped`.
- Do not say `Code Audit: skipped`.
- Do not say `SPEC.md: not needed`.
- Do not treat "trivial", "tiny", "single-file", or "local-only" as exceptions.
- If you are about to skip one of these phases, stop and complete the missing phase instead.

Research brief is mandatory:
- If `mcp__MiniMax__web_search` is available in the tool list, you MUST use it before planning, explaining, auditing, or editing.
- Use `mcp__MiniMax__web_search` as the primary external research tool when it is available.
- Fall back to Claude Code `WebSearch` only if the MiniMax MCP is unavailable.
- Deep research must follow the repo’s effectiveness-first `deepresearch` protocol rather than a generic search fan-out: start with a collaborative research plan, run an iterative search -> read -> refine loop, maintain a source ledger, resolve conflicting evidence, and do follow-up research before freezing the plan.
- Treat `MAX_PARALLEL_AGENTS` as a ceiling, not a quota.
- Choose an effective research budget based on the number of distinct questions that materially affect the plan.
- If the task is purely local and does not depend on current external facts, a concise local-only research brief is acceptable, but you must say why no external search was needed.
- Build a research brief before any code audit synthesis, spec creation, or code changes.
- Write a workflow artifact for file-changing tasks so the reasoning trail is inspectable.
- Hard-gate introspection must name likely mistakes, cite evidence checked, downgrade confidence when warranted, and block closeout when unresolved findings remain.
- Re-check any concrete library, framework, API, or error details again right before editing if the plan depends on them.

## Phase 0: Taste Gate

1. Check whether `taste.md` and `taste.vision` exist in the project root.
2. If they do not exist:
   - stop before research, audit, planning, or edits
   - tell the user that fresh repos must start with `/tastebootstrap`
   - do not ask the bootstrap questions here
   - do not write `taste.md` or `taste.vision` from inside `/workflow`
   - resume `/workflow` only after the kernel is defined
3. Read `taste.md` and `taste.vision`.
4. Rehydrate current working state if it exists:

```bash
bash scripts/state.sh status 2>/dev/null || true
```

Treat `.minimaxing/state/CURRENT.md` as a compact continuity handoff, then reconcile it with live `git status`, `SPEC.md`, and the latest workflow artifact before editing.

5. Recall memory for the task:

```bash
bash scripts/memory.sh recall "$ARGUMENTS" --depth medium 2>/dev/null || echo "Memory recall skipped"
bash scripts/memory-eval.sh --summary 2>/dev/null || echo "Memory freshness: unavailable; using local truth surfaces"
```

6. Summarize:
   - relevant taste principles
   - relevant working-state continuity and any stale assumptions to refresh
   - relevant recalled memories
   - memory health/freshness status and whether local truth surfaces are the
     fallback
   - an alignment score from 0 to 10
7. If the task clearly conflicts with taste, pause only to get an explicit alignment decision from the user.

If memory is `degraded`, `disabled`, or unavailable, continue from local truth
surfaces (`SPEC.md`, workflow artifacts, docs, git status, tests, and source
files) and say that memory could not be trusted as the primary context source.
Do not claim memory captured everything unless a memory event trace or durable
memory artifact proves the relevant entry exists.

## Phase 1: Route

Choose the route from user intent:

| Intent | Workflow Behavior |
|--------|-------------------|
| build, implement, create, add, refactor, optimize, migrate | run full research → audit → plan → spec → execute → verify → closeout flow |
| fix, debug, investigate | research first, audit the relevant code path, then reproduce/fix/verify; create `SPEC.md` if files change |
| audit, analyze, understand, deepresearch, webresearch | inspect deeply, report findings, make fixes only if the user asked for them |
| parallel, mode parallel, dense workflow, orchestrate subagents, split across instances | run the `/parallel` eligibility audit; use `/parallel` only when capacity, ownership, and verification pass |
| explain | inspect and explain directly |
| review | review directly |
| qa | run focused validation directly |
| visualize, visual approval, show me first, approve before implementation | route to `/visualizeworkflow` when the user wants implementation after visual approval; route to `/visualize` when the user only wants a comprehension artifact |

Default to the full build flow when the task changes files.

If a normal `/workflow` task has high visual or product-experience ambiguity,
you may mention that `/visualizeworkflow` exists for approval-first execution,
but continue autonomously unless the user asked for that approval pause.

For dense work, automatically consider `/parallel` even if the user did not
name it. Use it only when the eligibility audit proves independent packets,
clear ownership, host capacity, and a verification path. Downgrade to normal
inline `/workflow` when those conditions fail.

## Workflow Artifact

For file-changing tasks, create a durable workflow record before writing `SPEC.md`:

```bash
mkdir -p .taste/workflow-runs
STAMP="$(date +%Y%m%d-%H%M%S)"
WORKFLOW_ARTIFACT=".taste/workflow-runs/${STAMP}-workflow.md"
```

This artifact is the inspectable audit trail for the run. It must be created before `SPEC.md` and updated as phases complete.

Required section order:

```markdown
# Workflow Run: [task]

## Task
## Taste Gate
## Research Brief
## Code Audit
## Introspection
## Plan
## Agent-Native Estimate
## SPEC Decision
## Execution Notes
## Verification Evidence
## Outcome
```

Keep it concise, but do not skip sections. For non-file-changing analysis tasks, this artifact is optional.

Required content inside the sections:
- `## Research Brief` must record the investigation mode, collaborative research plan, effective research budget, iterative search -> read -> refine loop, source ledger, conflicting evidence, and any follow-up research required before planning.
- `## Introspection` must record at least `pre-plan` and `post-implementation` entries for file-changing work, plus `after-test-failure` or `pre-push` entries when those triggers occur.
- `## Plan` must record any delegated packets, their owners, and their dependencies when parallel execution is likely.
- `## Agent-Native Estimate` must record estimate type, execution topology,
  capacity evidence, effective lanes, critical path, agent wall-clock,
  agent-hours, human touch time, calendar blockers, confidence, and any
  human-equivalent baseline as secondary only.
- `## Execution Notes` must record any freshness re-checks and the final owned files touched by each delegated packet.
- If parallel run artifacts exist, `## Execution Notes` must record the
  `.taste/parallel/{run_id}` path and `scripts/parallel-aggregate.sh` output,
  including effective lanes, bottleneck, critical path, and any rejected worker
  claim.
- `## Verification Evidence` must include `Verification Metadata`: executor identity/model/workspace, verifier identity/model/workspace, and isolation status. Use `unknown` instead of implying separation when the run cannot prove it.
- `## Verification Evidence` must include command evidence for "tests passed"
  claims. Evidence-free closeout and failed-verification positive closeout are
  blocked by the effectiveness scorecard and Claude Code governance hook.
- When a workflow emits machine-consumed estimate, verification, or worker
  artifacts, add the matching minimal JSON sidecar and validate it with
  `scripts/artifact-lint.sh` before closeout.

When this lifecycle is reused by `/digestflow`, insert `## Report Intake` between `## Taste Gate` and `## Research Brief`. The intake section must record a report manifest, claim ledger, contradictions, injection quarantine, and the default `no-persist report bodies` decision. Imported claims remain `report-derived` until the repo's own deepresearch, live sources, or repo inspection upgrade them to `web-verified` or `repo-verified`.

## Phase 2: Deep Research

Every task gets a research-backed brief before planning or execution.

This phase is mandatory and cannot be satisfied by local repo inspection alone when the MiniMax MCP is available.

Research here should follow the repo’s own effectiveness-first `deepresearch` protocol, not a one-shot search batch. The goal is an inspectable investigation that plans first, then iteratively searches, reads, refines, and pressure-tests until the plan is grounded enough to act.

### Investigation Mode

Choose one mode up front and record it in the brief:
- `standard` — narrow implementation or debugging work with a small number of decisive questions
- `comprehensive` — audits, architecture, strategic planning, high-stakes debugging, security work, or any request that explicitly asks for deep research / top-quality investigation

Default to `comprehensive` for audits, planning, refactors, architecture, reverse engineering, and any task where the user explicitly asks for deep research or investigation quality.

### Research Requirements

1. Start from repo context:
   - inspect the codebase with targeted reads
   - identify the languages, frameworks, libraries, APIs, and likely problem area
   - avoid blind full-tree globs before you know what to inspect
2. Run memory recall first, then external research.
3. Draft a collaborative research plan before the first external wave. It must name:
   - the target deliverable
   - the core questions or branches to investigate
   - the source classes to consult
   - likely contradictions or unknowns to pressure-test
   - the stop condition for "research is sufficient to plan"
   - whether the user must review the plan before execution
4. Read the agent pool size:

```bash
MAX_AGENTS="${MAX_PARALLEL_AGENTS:-10}"
echo "$MAX_AGENTS"
```

5. Determine an effective research budget:
   - start at `MAX_AGENTS` as the ceiling
   - reduce it to the number of distinct, non-redundant research questions the task actually needs
   - allow `0` external tracks only when the task is purely local and no current external fact materially affects the plan
   - prefer fewer high-signal tracks over synthetic filler
6. Use the MiniMax MCP for live research:
   - official docs
   - recent best practices
   - release notes / version-specific behavior
   - GitHub issues or discussions for known pitfalls
   - alternatives or implementation patterns when architecture is involved
7. Launch the first discovery wave:
   - launch only distinct search tracks
   - issue the first wave of MiniMax MCP searches before broad local inspection
   - prefer sending many MCP search calls in the same response turn so they execute as a batch
   - do not widen the task just to consume slots
8. Read the returned sources before expanding the wave. The first batch should change what you search next.
9. Run an iterative search -> read -> refine loop:
   - Loop 1: discovery and landscape mapping
   - Loop 2: targeted deepening on the highest-value branches
   - Loop 3: adversarial verification for conflicting evidence, failure modes, or missing edges when the task is high-stakes or non-trivial
10. Maintain a source ledger throughout the investigation:
   - sources cited in the final brief
   - sources reviewed but not cited because they were duplicative, lower-signal, or merely confirmatory
   - rejected or downweighted sources when source quality is a material issue
11. For simple local tasks, use a smaller wave and focus on the highest-value angles:
   - implementation pattern
   - verification pattern
   - file-format conventions
   - safety / rollback pattern
   - repo-style precedent
   - testing approach
   - edge cases
   - dependency surface
   - portability concerns
   - maintenance implications
12. For debugging tasks, research the exact error, framework version, and any known regressions.
13. For security-sensitive, architecture, or strategy tasks, widen the search and cite multiple source classes.
14. When conflicting evidence appears, do not just pick the first convenient source. Weigh the evidence explicitly, record the conflict, and resolve or bracket it before moving on.
15. If key unknowns remain after the first synthesis, do follow-up research before code audit or planning. Do not move forward with unresolved core uncertainty unless the user must make the call.
16. If fewer than the effective budget complete because of a tool failure, redundant tracks, or the task simply not needing more angles, report the shortfall and reason explicitly.

For file-changing tasks that depend on current external facts, `Research Tracks Used` must not be `0 / ...` when the MiniMax MCP is available. For purely local tasks, `0` external tracks are allowed only with an explicit justification.

### Research Queries And Loops

Create only the focused tracks that materially change the plan. Expand or narrow them based on complexity, and stop when additional tracks would be redundant.

Core track ideas:
- official documentation for the libraries or frameworks involved
- latest best practices for the relevant technology
- version-specific change logs or migration notes
- GitHub issues/discussions for edge cases
- competitive or alternative patterns if a design decision is needed
- repo-specific pattern lookup from memory and local code search
- test and verification patterns
- performance considerations
- security considerations
- maintenance and operability concerns
- failure modes and rollback patterns
- repo promise / UX consistency checks
- competing implementation patterns
- production debugging or observability patterns

Do the MCP searches before relying on your own prior knowledge, but do not stop at the query list. Each wave should answer a concrete branch from the collaborative research plan.

Loop expectations:
- discovery wave -> map the landscape and surface candidate sources
- deep-read wave -> open the highest-value sources, extract facts, and identify gaps
- pressure-test wave -> search for conflicting evidence, failure modes, or missing edges when the task is non-trivial
- follow-up wave -> only when the plan or audit still depends on unresolved questions

### Research Output

Before moving on, produce a concise brief with:
- investigation mode
- collaborative research plan
- research track table with one row per track
- loop log that shows what changed between waves
- source ledger with cited sources, reviewed but not cited sources, and rejected or downweighted sources when relevant
- key facts
- conflicting evidence and how it was resolved or bracketed
- relevant sources or URLs
- concrete implications for the plan
- known pitfalls to avoid
- what still remains uncertain

Also include:
- number of MiniMax MCP searches performed
- effective research budget and why it was chosen
- research tracks completed versus planned
- whether any fallback WebSearch was used
- whether the task used a justified local-only research path
- whether follow-up research was required before planning or edits

Store important research findings in memory when they would be useful again:

```bash
bash scripts/memory.sh candidate semantic "Research [topic]: [key finding]. Source: [URL]" --verified yes --source "$WORKFLOW_ARTIFACT" --tags "research,[topic],current"
```

Only promote a candidate with `bash scripts/memory.sh add ...` after verification
proves the finding is reusable and safe for the public repo. Never store
customer memory seeds, private commercial playbooks, real credentials, private
connector details, or customer-specific Hermes/REVCLI runtime facts in tracked
public memory.

For file-changing tasks, record the research brief in `WORKFLOW_ARTIFACT` before continuing.

Do not create or update `SPEC.md` until this brief exists.

## Phase 3: Code Audit

After research, audit the current codebase before planning.

For file-changing work, this phase is mandatory even when the audit is tiny. A minimal audit is still an audit:
- "single new file in project root"
- "no existing module dependency"
- "no pre-existing tests in scope"

If files will change, report `Code Audit: completed`, not skipped.

For the relevant files, commands, and subsystems:

1. Identify the exact change surface:
   - files likely to change
   - tests that already cover the area
   - configs, scripts, commands, or docs that constrain the change
2. Capture current implementation reality:
   - architecture or module boundaries
   - existing patterns and naming conventions
   - framework/runtime versions that matter
   - dependencies or coupling that change the plan
3. Identify risk:
   - migration risk
   - backwards-compatibility risk
   - missing tests
   - rollout or rollback risk
4. For bug/fix work, document:
   - current failure mode
   - suspected root cause
   - evidence gathered so far

Write a concise `## Code Audit` section into `WORKFLOW_ARTIFACT` with:
- current state
- key files
- constraints
- risks
- verification surface

Do not write `SPEC.md` until this code audit is captured.

## Phase 4: Plan

Before planning, run hard-gate introspection.

### Pre-plan Introspection

Use `/introspect pre-plan` as the playbook, but execute inline.

Check:
- likely mistakes in the research brief or code audit
- assumptions that are not supported by evidence
- counterexamples or missing edge cases
- places where external facts, source quality, or repo inspection are too weak
- whether the plan would violate taste, `SPEC.md` lifecycle, or existing patterns

Append the result to `## Introspection` in `WORKFLOW_ARTIFACT` before writing `## Plan`.

Required decision:
- `PASS` -> continue to plan
- `FIX_REQUIRED` -> gather more evidence or correct the audit before planning
- `REPLAN_REQUIRED` -> change direction before writing `SPEC.md`
- `BLOCKED` -> stop and explain the blocker

Synthesize the research brief and code audit into an execution plan before writing `SPEC.md`.

The plan must answer:
- what exactly will change
- what will explicitly not change
- what the smallest sufficient implementation is
- which abstractions, refactors, or adjacent cleanup are explicitly out of scope
- why this approach is the best fit for this repo
- what risks or unknowns remain
- how the work will be verified
- what the rollback path is when relevant

For file-changing tasks:
1. Write a concise `## Plan` section into `WORKFLOW_ARTIFACT`.
2. Keep the plan concrete enough that `SPEC.md` can be derived directly from it.
3. If the best answer is "do not change code yet", say so explicitly and stop before execution.

Do not create or update `SPEC.md` until this plan exists.

### Agent-Native Estimate

Before `SPEC.md` is written, replaced, or reused, append `## Agent-Native
Estimate` to `WORKFLOW_ARTIFACT`.

Use this stable block:

```markdown
## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local | subagents | parallel-instances | agent-teams-experimental
- Capacity evidence: scripts/parallel-capacity.sh --json, Codex max_threads, MAX_PARALLEL_AGENTS
- Effective lanes: N of ceiling M
- Critical path: P1 -> P4 -> P7
- Agent wall-clock: optimistic / likely / pessimistic
- Agent-hours: total active work across all lanes
- Human touch time: review, approval, credentials, product decisions
- Calendar blockers: CI queue, deploy window, external account setup, rate limits, business-hours dependency
- Confidence: high | medium | low, with downgrade reason
- Human-equivalent baseline: optional secondary comparison only
```

Rules:
- estimate elapsed time from the task DAG and the longest dependency path, not
  summed packet effort
- never divide a human-week estimate by the lane count
- never assume 24/7 parallelism unless ownership, capacity, dependencies, and
  verification support it
- include verification, aggregation, review, and expected rework time
- use `blocked/unknown` instead of false precision when capacity, credentials,
  CI, deploy windows, or product decisions are missing

Do not create, update, or reuse `SPEC.md` until this estimate exists for
non-trivial file-changing work.

## Phase 5: Spec

For file-changing work:

1. Decide whether the active `SPEC.md` is reusable for this exact task before editing it.
   - If it matches the current task, reuse it and do not archive it yet.
   - If it does not match and you will create or rewrite `SPEC.md`, archive the previous active spec first:

```bash
bash scripts/spec-archive.sh prepare "$ARGUMENTS" "superseded-before-new-spec" 2>/dev/null || true
```

2. Create or update `SPEC.md` directly in this workflow after research, audit, and planning are complete.
   - `SPEC.md` must be a real file in the working directory.
   - Do not satisfy this phase only inside `WORKFLOW_ARTIFACT`.
3. Keep the spec concrete and short enough to execute now.
4. Derive it from the approved plan rather than improvising new scope.
5. Include:
   - problem statement
   - repo constraints / codebase anchors
   - success criteria
   - scope
   - smallest sufficient implementation
   - explicit non-goals / no drive-by refactors
   - Agent-Native Estimate
   - implementation plan
   - verification
   - rollback plan when relevant
5. Use this structure unless a stronger existing project format already covers the same information:

```markdown
# SPEC: [task name]

## Problem Statement
[1-2 sentence statement of the change]

## Codebase Anchors
- Relevant existing files, modules, or configs
- Constraints or patterns that must be preserved

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Scope
### In Scope
- ...

### Out of Scope
- ...

## Surgical Diff Discipline
- Smallest sufficient implementation: [what is the narrowest change that satisfies the request]
- No speculative abstractions: [what flexibility, configurability, or refactor is intentionally avoided]
- No drive-by refactors: [adjacent cleanup not required by the spec]
- Changed-line trace: [how changed files or sections map to success criteria]

## Agent-Native Estimate
- Estimate type: agent-native wall-clock
- Execution topology: [local|subagents|parallel-instances|agent-teams-experimental]
- Capacity evidence: [scripts/parallel-capacity.sh --json or other source]
- Effective lanes: [N of ceiling M]
- Critical path: [longest dependency path]
- Agent wall-clock: [optimistic / likely / pessimistic]
- Agent-hours: [total active work across all lanes]
- Human touch time: [review/approval/credentials/product decisions]
- Calendar blockers: [CI/deploy/account/rate-limit/business-hours blockers]
- Confidence: [high|medium|low with reason]
- Human-equivalent baseline: [optional secondary comparison only]

## Implementation Plan
1. ...
2. ...

## Verification
- Criterion 1 -> [command, test, or inspection]
- Criterion 2 -> [command, test, or inspection]

## Rollback Plan
- [how to undo safely]
```

6. If a suitable `SPEC.md` already exists and matches the task, reuse it instead of rewriting it.
7. For tiny local tasks, keep the spec intentionally small rather than inflating it, but do not omit `## Codebase Anchors`.
8. Update the `## SPEC Decision` section in `WORKFLOW_ARTIFACT` with whether `SPEC.md` was created, updated, or reused, record the file path, and record the archive path or "not needed because reused/new workspace".

Do not stop after `SPEC.md` is written.

## Phase 6: Execute

Implement directly with Claude Code tools.

- Make the necessary file changes.
- Re-check any version-sensitive or API-sensitive assumptions from the research brief immediately before editing when necessary.
- Use `/parallel` for dense work when the eligibility audit, hardware capacity profile, ownership matrix, and verification plan show real critical-path reduction.
- Use subagents or parallel work only when it materially helps and file ownership is clear.
- Give every delegated packet a thin brief with owned files, dependencies, stop conditions, and expected evidence.
- If `/parallel` is used, record the selected substrate (`local`, `subagents`, `parallel-instances`, or experimental `agent-teams`), effective budget, packet DAG, ownership matrix, and sync barriers in the workflow artifact or a dedicated `.taste/workflow-runs/*-parallel.md` artifact.
- Prefer direct execution over theatrical parallelism for tiny tasks.
- Keep changes aligned with the spec and taste constraints.
- Keep the diff surgical: do not refactor, reformat, rename, or "improve" adjacent code unless the active `SPEC.md` requires it.
- Remove only unused imports, variables, files, or docs that your own changes orphaned; mention pre-existing dead code instead of deleting it.
- Update `## Execution Notes` in `WORKFLOW_ARTIFACT` with the files changed and any notable deviations from the plan.
- After implementation, run `/introspect post-implementation` inline and append the result to `## Introspection`. Check the diff against `SPEC.md`, likely mistakes, missing edge cases, weak verification, speculative abstractions, drive-by refactors, and changed-line trace gaps before moving on.

If the task is non-code analysis, do the work directly and skip implementation.

## Phase 7: Verify

Verify against `SPEC.md` inside this same workflow.

Required verification behavior:
- read the relevant files
- run the relevant commands or tests
- gather concrete evidence
- compare actual behavior against every success criterion

If verification fails:
1. run `/introspect after-test-failure` inline and append the result to `## Introspection`
2. identify whether the fix path, plan, spec, or test expectation is wrong
3. fix the issue only after the introspection pass names the likely mistake
4. verify again
5. repeat until the result is accepted or a real blocker remains

Never declare success without evidence.

For file-changing tasks, update `## Verification Evidence` in `WORKFLOW_ARTIFACT` with:
- Verification Metadata: executor identity/model/workspace, verifier identity/model/workspace, and isolation status (`proved separate`, `same session independent pass`, or `unknown`)
- commands run
- files inspected
- which success criteria passed
- changed-line trace from modified files or sections back to `SPEC.md`
- Actual Timing when known: `started_at`, `plan_frozen_at`,
  `implementation_started_at`, `verification_completed_at`, `closed_at`,
  effective lanes used, failed verification count, and human blocker minutes
- any residual risk

## Pre-Closeout Gate

Before you emit `## Workflow Complete` for a file-changing task, confirm all of these are true:

- `Research Tracks Used` shows the effective budget met, a justified local-only path, or an explicitly justified shortfall.
- The research brief records the investigation mode, collaborative research plan, loop log, and source ledger when external facts matter.
- `Code Audit` is completed.
- `Introspection` includes a `pre-plan` pass and a `post-implementation` or justified non-implementation pass.
- Failed verification, if any, has an `after-test-failure` introspection entry before the next fix attempt.
- `Plan` is completed.
- `Agent-Native Estimate` exists, is agent-native by default, includes
  confidence, and is not only a human-equivalent baseline.
- `SPEC.md` exists on disk as a real file.
- `WORKFLOW_ARTIFACT` exists and its phase sections are filled in.
- Implementation is done or explicitly not required.
- Verification includes concrete evidence.
- Verification metadata is recorded without overstating executor/verifier isolation.
- The changed-line trace is satisfied: every meaningful diff maps to `SPEC.md`, generated output, or cleanup caused by this change.
- No speculative abstractions or drive-by refactors remain in the diff.
- Actual timing fields are recorded when they are known; unknown values are
  labeled `unknown` instead of invented.

If any item above is false, continue the workflow instead of closing out.

## Phase 8: Closeout

Close out based on what the user actually asked for.

### For local implementation tasks

If the user did not explicitly ask to commit, push, deploy, or publish:
- stop after verified local completion
- keep the workflow artifact under `.taste/workflow-runs/`
- archive the final active spec with the verified outcome:

```bash
bash scripts/spec-archive.sh closeout "$ARGUMENTS" "verified: [short outcome]" 2>/dev/null || true
```

- summarize what changed and how it was verified

### For explicit ship or push requests

Only perform remote-facing actions when the user clearly asked for them.

If the user explicitly wants a push or ship:
1. confirm the repo is in a sane git state
2. commit intentionally
3. run `/introspect pre-push` inline and append the result to `## Introspection`; do not push with unresolved blockers
4. archive the final active spec with the shipped outcome before or immediately after the commit:

```bash
bash scripts/spec-archive.sh closeout "$ARGUMENTS" "shipped: [short outcome]" 2>/dev/null || true
```

5. push only if a remote exists and the request includes pushing
6. never invent deployment steps that are not present in the repo

## Specialist Skills

The project still provides specialist commands like `/autoplan`, `/digestflow`, `/deepresearch`, `/webresearch`, `/browse`, `/introspect`, `/parallel`, `/sprint`, `/verify`, `/audit`, `/visualize`, `/visualizeworkflow`, and `/ship`.

Use them like this:
- as direct user-invoked helpers
- as reference playbooks when useful
- not as required nested links in the core `/workflow` execution path

## Output

When complete, return:

```markdown
## Workflow Complete

- Task: [task]
- Taste Gate: PASS / BOOTSTRAPPED / REALIGNED
- Research: [completed with MiniMax MCP / local-only brief / fallback used / blocked]
- Research Mode: [standard / comprehensive]
- Research Tracks Used: [completed] / [effective budget] (ceiling [MAX_PARALLEL_AGENTS])
- MiniMax MCP Searches: [count]
- Follow-up Research: [not needed / completed / blocked]
- Code Audit: [completed / skipped only for non-file-changing analysis / blocked]
- Introspection: [PASS / FIX_REQUIRED / REPLAN_REQUIRED / BLOCKED]
- Plan: [completed / skipped / blocked]
- Agent-Native Estimate: [completed / blocked / not applicable for tiny direct task]
- SPEC.md: [created / updated / reused / blocked]
- Surgical Diff: [PASS / FIX_REQUIRED / not applicable]
- Spec Archive: [archived / already archived / not needed / blocked]
- Implementation: [done / not needed]
- Verification: ACCEPT / REJECT / BLOCKED
- Remote Actions: none / committed / pushed / deployed
- Workflow Artifact: [path or not created]
- Key Files: [important files]
- Open Blockers: [none or list]
```

## Anti-Patterns

- stopping after writing `SPEC.md`
- overwriting a non-reused `SPEC.md` without archiving it to `.taste/specs/`
- planning from memory alone without a research brief
- skipping MiniMax MCP research when current external facts matter and the tool is available
- treating deep research as a one-shot search batch instead of a collaborative research plan plus iterative search -> read -> refine loop
- omitting a source ledger when external facts materially affect the plan
- citing only supporting sources while ignoring conflicting evidence
- moving to code audit or planning while core research unknowns still require follow-up research
- planning, closing out, or pushing while introspection blockers remain unresolved
- treating `/review` as a substitute for `/introspect`
- turning plain `/workflow` into a visual-approval workflow; use
  `/visualizeworkflow` for `WAITING_FOR_VISUAL_APPROVAL`
- running redundant search tracks just to hit the ceiling
- delegating without owned files, dependencies, or a stop condition
- broad `Glob("*")` exploration before the first research wave
- skipping a code audit before planning for file-changing work
- creating `SPEC.md` before the plan exists
- creating, reusing, or freezing `SPEC.md` before `## Agent-Native Estimate`
  exists for non-trivial work
- giving only a human-equivalent estimate such as "6 weeks" without
  agent-native wall-clock, critical path, blockers, and confidence
- claiming linear scaling such as "10 agents means 10x faster"
- claiming `SPEC.md` was not needed for file-changing work
- claiming `SPEC.md` was created when the only copy lives inside `WORKFLOW_ARTIFACT`
- adding speculative abstractions, options, or configurability not required by the spec
- drive-by refactors, formatting churn, comment rewrites, or adjacent cleanup without a `SPEC.md` reason
- closing out without a changed-line trace for the meaningful diff
- editing code before the research brief exists
- telling the user to manually invoke the next phase
- claiming verification without commands or evidence
- pushing or deploying when the user only asked for a local result
- using nested custom-skill chaining as if it were guaranteed orchestration
- treating trivial file changes as exempt from research, code audit, or `SPEC.md`
