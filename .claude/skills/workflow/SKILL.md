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
- Do not stop after planning.
- Do not tell the user to manually run `/autoplan`, `/sprint`, `/verify`, or `/ship`.
- Do not rely on nested custom-skill chaining as the primary execution path.

Reason:
In real Claude Code sessions, nested custom skills may complete their own turn and return control to the user before the rest of the chain runs. For `/workflow`, execute the phases inline with Claude Code tools so the full flow actually completes.

You may still use built-in Claude Code tools, shell commands, subagents, and optional specialist skills as reference material when useful, but `/workflow` itself owns the whole lifecycle.

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

## Phase 2: Spec

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

## Phase 3: Execute

Implement directly with Claude Code tools.

- Make the necessary file changes.
- Use subagents or parallel work only when it materially helps and file ownership is clear.
- Prefer direct execution over theatrical parallelism for tiny tasks.
- Keep changes aligned with the spec and taste constraints.

If the task is non-code analysis, do the work directly and skip implementation.

## Phase 4: Verify

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

## Phase 5: Closeout

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
- SPEC.md: [created, updated, reused, or not needed]
- Implementation: [done / not needed]
- Verification: ACCEPT / REJECT / BLOCKED
- Remote Actions: none / committed / pushed / deployed
- Key Files: [important files]
- Open Blockers: [none or list]
```

## Anti-Patterns

- stopping after writing `SPEC.md`
- telling the user to manually invoke the next phase
- claiming verification without commands or evidence
- pushing or deploying when the user only asked for a local result
- using nested custom-skill chaining as if it were guaranteed orchestration
