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
- Do max-agent deep research for every task before planning or execution.
- Do not stop after planning.
- Do not tell the user to manually run `/autoplan`, `/sprint`, `/verify`, or `/ship`.
- Do not rely on nested custom-skill chaining as the primary execution path.

Reason:
In real Claude Code sessions, nested custom skills may complete their own turn and return control to the user before the rest of the chain runs. For `/workflow`, execute the phases inline with Claude Code tools so the full flow actually completes.

You may still use built-in Claude Code tools, shell commands, subagents, and optional specialist skills as reference material when useful, but `/workflow` itself owns the whole lifecycle.

Research is mandatory:
- If `mcp__MiniMax__web_search` is available in the tool list, you MUST use it before planning, explaining, auditing, or editing.
- Use `mcp__MiniMax__web_search` as the primary external research tool when it is available.
- Fall back to Claude Code `WebSearch` only if the MiniMax MCP is unavailable.
- Always use the full `MAX_PARALLEL_AGENTS` pool for research fan-out.
- The target research count is exactly `MAX_PARALLEL_AGENTS` live search tracks on every run when MiniMax MCP is available.
- Build a research brief before spec creation or code changes.
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
| build, implement, create, add, refactor, optimize, migrate | run full spec → execute → verify → closeout flow |
| fix, debug, investigate | reproduce if needed, fix, verify, closeout |
| audit, analyze, understand | inspect deeply, report findings, make fixes only if the user asked for them |
| explain | inspect and explain directly |
| review | review directly |
| qa | run focused validation directly |

Default to the full build flow when the task changes files.

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

Do not create or update `SPEC.md` until this brief exists.

## Phase 3: Spec

For file-changing work:

1. Create or update `SPEC.md` directly in this workflow.
2. Keep the spec concrete and short enough to execute now.
3. Include:
   - problem statement
   - success criteria
   - scope
   - implementation plan
   - verification
   - rollback plan when relevant
4. If a suitable `SPEC.md` already exists and matches the task, reuse it instead of rewriting it.
5. For tiny local tasks, keep the spec intentionally small rather than inflating it.

Do not stop after `SPEC.md` is written.

## Phase 4: Execute

Implement directly with Claude Code tools.

- Make the necessary file changes.
- Re-check any version-sensitive or API-sensitive assumptions from the research brief immediately before editing when necessary.
- Use subagents or parallel work only when it materially helps and file ownership is clear.
- Prefer direct execution over theatrical parallelism for tiny tasks.
- Keep changes aligned with the spec and taste constraints.

If the task is non-code analysis, do the work directly and skip implementation.

## Phase 5: Verify

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

## Phase 6: Closeout

Close out based on what the user actually asked for.

### For local implementation tasks

If the user did not explicitly ask to commit, push, deploy, or publish:
- stop after verified local completion
- write a workflow artifact under `.taste/workflow-runs/` when appropriate
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
- SPEC.md: [created, updated, reused, or not needed]
- Implementation: [done / not needed]
- Verification: ACCEPT / REJECT / BLOCKED
- Remote Actions: none / committed / pushed / deployed
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
- editing code before the research brief exists
- telling the user to manually invoke the next phase
- claiming verification without commands or evidence
- pushing or deploying when the user only asked for a local result
- using nested custom-skill chaining as if it were guaranteed orchestration
