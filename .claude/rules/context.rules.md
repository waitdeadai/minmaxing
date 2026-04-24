# Context Rules

## Fresh Context Discipline

### SPEC.md as Reset Mechanism

When starting a new task or feature, SPEC.md acts as a context reset:
- New SPEC.md = new clean context
- Previous SPEC.md = archive to `.taste/specs/` before replacement unless it is being reused
- Read SPEC.md from scratch for each major task
- Don't carry stale context from previous tasks

### Context Rot Prevention

Context degrades as conversation lengthens:

| Turns | Quality |
|-------|---------|
| 0-30 | Peak — thorough, comprehensive |
| 30-50 | Good — some corner cutting |
| 50+ | Degraded — rushing, missed requirements |

**When to consider context refresh:**
- After 50+ turns
- When responses get shorter
- When instructions get missed
- When you feel "lost"

### When to Compact

When context is 50+ turns long, you notice missed instructions, or discussion has drifted from original topic.
- Discussion has drifted from original topic
- You need a fresh start on the same project

### Compaction-Safe Working State

minmaxing persists a compact working state in `.minimaxing/state/CURRENT.md`.
This is the live task handoff that survives startup, resume, and compaction.

Use it for ephemeral execution context:
- active task and current phase
- files in play
- latest `SPEC.md` and workflow artifact pointers
- last compact summary
- verification status and next action hints

Do not use working state as durable memory. Durable lessons, decisions, errors,
and reusable patterns belong in `bash scripts/memory.sh add ...`.

After compaction or resume:
- read injected working state from the SessionStart hook
- reconcile it with live `git status`
- re-open `SPEC.md` and the latest `.taste/workflow-runs/*-workflow.md` when they exist
- check `.taste/specs/` only for historical context; the active contract remains `SPEC.md`
- refresh stale assumptions before editing

## Sub-Agent Context Isolation

Each parallel agent gets its own clean context:

- **No shared state** between agents
- **Fresh working context** seeded from a thin handoff, not the whole parent thread
- **Clean handoff** — only pass what's needed right now
- **Aggregator combines results**, not context

**Why:** Context pollution causes file conflicts, missed requirements, and stale decisions.

## Progressive Disclosure

Load context in layers, not all at once:

| Level | Content | When |
|-------|----------|-------|
| 1 | Current file/module | Always |
| 2 | Project-wide (CLAUDE.md) | When needed |
| 3 | Cross-session (memory) | When relevant |
| 4 | External (web search) | When researching |

## Context Management

- Read CLAUDE.md for project context
- Use `.minimaxing/state/CURRENT.md` for current-task continuity after compaction
- Use memory for cross-session context
- Use web search for external context
- Keep current task context minimal
- When in doubt, ask "is this still accurate?"

## Freshness Checkpoints

Before a parallel agent acts, confirm:

- the spec or task brief is still current
- its owned files or surfaces have not changed under it
- its dependencies are satisfied
- the evidence it relies on is still relevant

If any checkpoint fails, stop, refresh the brief, and re-sync before continuing.

## Anti-Patterns

- Carrying stale context across tasks → BLOCK
- Ignoring context rot symptoms → BLOCK
- Overloading context with irrelevant info → BLOCK
- Not using SPEC.md as reset point → WARN
- Overwriting active SPEC.md without archive → BLOCK
- Treating `.minimaxing/state/CURRENT.md` as verified without reconciling live repo state → BLOCK
- Sharing context between parallel agents → BLOCK
- Passing the full parent conversation to every agent → BLOCK
- Acting on a stale brief after dependencies changed → BLOCK
