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

## Non-Negotiable Contract

- Finish the task in this command whenever it is feasible.
- For file-changing work, follow this order: deep research -> code audit -> plan -> `SPEC.md` -> execute -> verify.
- Do max-agent deep research for every task before planning or execution.
- Audit the current codebase before planning or writing `SPEC.md`.
- Synthesize a concrete plan before writing `SPEC.md`.
- Do not stop after planning.
- Do not tell the user to manually run `/autoplan`, `/sprint`, `/verify`, or `/ship`.
- Do not rely on nested custom-skill chaining as the primary execution path.

Reason:
In real Claude Code sessions, nested custom skills may complete their own turn and return control to the user before the rest of the chain runs. For `/workflow`, execute the phases inline with Claude Code tools so the full flow actually completes.

You may still use built-in Claude Code tools, shell commands, subagents, and optional specialist skills as reference material when useful, but `/workflow` itself owns the whole lifecycle.

No shortcut exceptions for file-changing tasks:
- Do not say `Research: skipped`.
- Do not say `Code Audit: skipped`.
- Do not say `SPEC.md: not needed`.
- Do not treat "trivial", "tiny", "single-file", or "local-only" as exceptions.
- If you are about to skip one of these phases, stop and complete the missing phase instead.

Research is mandatory:
- If `mcp__MiniMax__web_search` is available in the tool list, you MUST use it before planning, explaining, auditing, or editing.
- Use `mcp__MiniMax__web_search` as the primary external research tool when it is available.
- Fall back to Claude Code `WebSearch` only if the MiniMax MCP is unavailable.
- Always use the full `MAX_PARALLEL_AGENTS` pool for research fan-out.
- The target research count is exactly `MAX_PARALLEL_AGENTS` live search tracks on every run when MiniMax MCP is available.
- Build a research brief before any code audit synthesis, spec creation, or code changes.
- Write a workflow artifact for file-changing tasks so the reasoning trail is inspectable.
- Re-check any concrete library, framework, API, or error details again right before editing if the plan depends on them.

## Phase 0: Taste Gate

1. Check whether `taste.md` and `taste.vision` exist in the project root.
2. If they do not exist, bootstrap taste inline instead of bouncing the user elsewhere:
   - ask the 10 bootstrap questions directly
   - write `taste.md` and `taste.vision`
   - then continue automatically
3. Read `taste.md` and `taste.vision`.
4. Recall memory for the task:

```bash
bash scripts/memory.sh recall "$ARGUMENTS" --depth medium 2>/dev/null || echo "Memory recall skipped"
```

5. Summarize:
   - relevant taste principles
   - relevant recalled memories
   - an alignment score from 0 to 10
6. If the task clearly conflicts with taste, pause only to get an explicit alignment decision from the user.

## Phase 1: Route

Choose the route from user intent:

| Intent | Workflow Behavior |
|--------|-------------------|
| build, implement, create, add, refactor, optimize, migrate | run full research → audit → plan → spec → execute → verify → closeout flow |
| fix, debug, investigate | research first, audit the relevant code path, then reproduce/fix/verify; create `SPEC.md` if files change |
| audit, analyze, understand | inspect deeply, report findings, make fixes only if the user asked for them |
| explain | inspect and explain directly |
| review | review directly |
| qa | run focused validation directly |

Default to the full build flow when the task changes files.

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
## Plan
## SPEC Decision
## Execution Notes
## Verification Evidence
## Outcome
```

Keep it concise, but do not skip sections. For non-file-changing analysis tasks, this artifact is optional.

## Phase 2: Deep Research

Every task gets a research-backed brief before planning or execution.

This phase is mandatory and cannot be satisfied by local repo inspection alone when the MiniMax MCP is available.

### Research Requirements

1. Start from repo context:
   - inspect the codebase with targeted reads
   - identify the languages, frameworks, libraries, APIs, and likely problem area
   - avoid blind full-tree globs before you know what to inspect
2. Run memory recall first, then external research.
3. Read the agent pool size:

```bash
MAX_AGENTS="${MAX_PARALLEL_AGENTS:-10}"
echo "$MAX_AGENTS"
```

4. Decompose the work into exactly `MAX_AGENTS` research tracks.
5. Use the MiniMax MCP for live research:
   - official docs
   - recent best practices
   - release notes / version-specific behavior
   - GitHub issues or discussions for known pitfalls
   - alternatives or implementation patterns when architecture is involved
6. Fill the entire research pool every time:
   - launch `MAX_AGENTS` distinct search tracks
   - issue the first wave of MiniMax MCP searches before broad local inspection
   - prefer sending many MCP search calls in the same response turn so they execute as a batch
   - do not leave slots idle
   - split the task into narrower angles until all tracks are used
7. For simple local tasks, still use all research slots by widening the lens:
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
8. For debugging tasks, research the exact error, framework version, and any known regressions.
9. For security-sensitive or architecture tasks, widen the search and cite multiple sources.
10. If fewer than `MAX_AGENTS` live searches complete because of a tool or network failure, retry first and then explicitly report the shortfall and reason.

For file-changing tasks, `Research Tracks Used` must not be `0 / ...` when the MiniMax MCP is available.

### Research Queries

Create exactly `MAX_PARALLEL_AGENTS` focused tracks every time. Expand or narrow them based on complexity, but fill the pool.

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

Do the MCP searches before relying on your own prior knowledge.

### Research Output

Before moving on, produce a concise brief with:
- research track table with one row per track
- key facts
- relevant sources or URLs
- concrete implications for the plan
- known pitfalls to avoid
- what still remains uncertain

Also include:
- number of MiniMax MCP searches performed
- `MAX_PARALLEL_AGENTS` used for research
- research tracks completed versus expected
- whether any fallback WebSearch was used

Store important research findings in memory when they would be useful again:

```bash
bash scripts/memory.sh add semantic "Research [topic]: [key finding]. Source: [URL]" --tags "research,[topic],current"
```

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

Synthesize the research brief and code audit into an execution plan before writing `SPEC.md`.

The plan must answer:
- what exactly will change
- what will explicitly not change
- why this approach is the best fit for this repo
- what risks or unknowns remain
- how the work will be verified
- what the rollback path is when relevant

For file-changing tasks:
1. Write a concise `## Plan` section into `WORKFLOW_ARTIFACT`.
2. Keep the plan concrete enough that `SPEC.md` can be derived directly from it.
3. If the best answer is "do not change code yet", say so explicitly and stop before execution.

Do not create or update `SPEC.md` until this plan exists.

## Phase 5: Spec

For file-changing work:

1. Create or update `SPEC.md` directly in this workflow after research, audit, and planning are complete.
   - `SPEC.md` must be a real file in the working directory.
   - Do not satisfy this phase only inside `WORKFLOW_ARTIFACT`.
2. Keep the spec concrete and short enough to execute now.
3. Derive it from the approved plan rather than improvising new scope.
4. Include:
   - problem statement
   - repo constraints / codebase anchors
   - success criteria
   - scope
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
8. Update the `## SPEC Decision` section in `WORKFLOW_ARTIFACT` with whether `SPEC.md` was created, updated, or reused, and record the file path.

Do not stop after `SPEC.md` is written.

## Phase 6: Execute

Implement directly with Claude Code tools.

- Make the necessary file changes.
- Re-check any version-sensitive or API-sensitive assumptions from the research brief immediately before editing when necessary.
- Use subagents or parallel work only when it materially helps and file ownership is clear.
- Prefer direct execution over theatrical parallelism for tiny tasks.
- Keep changes aligned with the spec and taste constraints.
- Update `## Execution Notes` in `WORKFLOW_ARTIFACT` with the files changed and any notable deviations from the plan.

If the task is non-code analysis, do the work directly and skip implementation.

## Phase 7: Verify

Verify against `SPEC.md` inside this same workflow.

Required verification behavior:
- read the relevant files
- run the relevant commands or tests
- gather concrete evidence
- compare actual behavior against every success criterion

If verification fails:
1. fix the issue
2. verify again
3. repeat until the result is accepted or a real blocker remains

Never declare success without evidence.

For file-changing tasks, update `## Verification Evidence` in `WORKFLOW_ARTIFACT` with:
- commands run
- files inspected
- which success criteria passed
- any residual risk

## Pre-Closeout Gate

Before you emit `## Workflow Complete` for a file-changing task, confirm all of these are true:

- `Research Tracks Used` shows the full pool or an explicitly justified shortfall.
- `Code Audit` is completed.
- `Plan` is completed.
- `SPEC.md` exists on disk as a real file.
- `WORKFLOW_ARTIFACT` exists and its phase sections are filled in.
- Implementation is done or explicitly not required.
- Verification includes concrete evidence.

If any item above is false, continue the workflow instead of closing out.

## Phase 8: Closeout

Close out based on what the user actually asked for.

### For local implementation tasks

If the user did not explicitly ask to commit, push, deploy, or publish:
- stop after verified local completion
- keep the workflow artifact under `.taste/workflow-runs/`
- summarize what changed and how it was verified

### For explicit ship or push requests

Only perform remote-facing actions when the user clearly asked for them.

If the user explicitly wants a push or ship:
1. confirm the repo is in a sane git state
2. commit intentionally
3. push only if a remote exists and the request includes pushing
4. never invent deployment steps that are not present in the repo

## Specialist Skills

The project still provides specialist commands like `/autoplan`, `/sprint`, `/verify`, `/audit`, and `/ship`.

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
- Research: [completed with MiniMax MCP / fallback used / blocked]
- Research Tracks Used: [completed] / [MAX_PARALLEL_AGENTS]
- MiniMax MCP Searches: [count]
- Code Audit: [completed / skipped only for non-file-changing analysis / blocked]
- Plan: [completed / skipped / blocked]
- SPEC.md: [created, updated, reused, or not needed]
- Implementation: [done / not needed]
- Verification: ACCEPT / REJECT / BLOCKED
- Remote Actions: none / committed / pushed / deployed
- Workflow Artifact: [path or not created]
- Key Files: [important files]
- Open Blockers: [none or list]
```

## Anti-Patterns

- stopping after writing `SPEC.md`
- planning from memory alone without live research
- skipping MiniMax MCP research when the tool is available
- running fewer than `MAX_PARALLEL_AGENTS` live search tracks when MiniMax MCP is available and healthy
- leaving research slots idle when `MAX_PARALLEL_AGENTS` could cover more angles
- broad `Glob("*")` exploration before the first research wave
- skipping a code audit before planning for file-changing work
- creating `SPEC.md` before the plan exists
- claiming `SPEC.md` was created when the only copy lives inside `WORKFLOW_ARTIFACT`
- editing code before the research brief exists
- telling the user to manually invoke the next phase
- claiming verification without commands or evidence
- pushing or deploying when the user only asked for a local result
- using nested custom-skill chaining as if it were guaranteed orchestration
- treating trivial file changes as exempt from research, code audit, or `SPEC.md`
