# Context Rules

## Fresh Context Discipline

### SPEC.md as Reset Mechanism

When starting a new task or feature, SPEC.md acts as a context reset:
- New SPEC.md = new clean context
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

Use `/compact` when:
- Context is 50+ turns long
- You notice missed instructions
- Discussion has drifted from original topic
- You need a fresh start on the same project

## Sub-Agent Context Isolation

Each parallel agent gets its own clean context:

- **No shared state** between agents
- **No context inheritance** from parent
- **Clean handoff** — only pass what's needed
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
- Use memory for cross-session context
- Use web search for external context
- Keep current task context minimal
- When in doubt, ask "is this still accurate?"

## Anti-Patterns

- Carrying stale context across tasks → BLOCK
- Ignoring context rot symptoms → BLOCK
- Overloading context with irrelevant info → BLOCK
- Not using SPEC.md as reset point → WARN
- Sharing context between parallel agents → BLOCK
