---
description: Autonomous SOTA workflow - drives full implementation loop automatically
---

# /workflow

**THE AUTONOMOUS WORKFLOW** — One command drives the entire implementation loop automatically. AI acts as technical lead, routing to you only at decision points.

**Use when:** User says "build X", "implement Y", "fix Z", or any substantial task.

**Research-backed:** Agent Teams pattern, TDD loops, Director Mode, Agentic Flywheel with active memory feedback. **Research-First:** Live data from web, not stale training data.

---

## The Loop (Automated)

### Phase 0: Memory Check (before anything)
- Query ForgeGod CLI for similar past tasks: `forgegod memory`
- Check what worked, what failed, what user rejected
- Adjust approach based on past feedback
- If memory has guidance for this task type → apply it

### Phase 0.5: Research First (MANDATORY)
**Web research is NOT optional.** AI training data is stale. Every task starts with research to get current facts.

**Research triggers — ALWAYS search when task involves:**
- External APIs or SDKs (pricing, limits, new versions)
- Libraries or frameworks (latest version, breaking changes, alternatives)
- Error messages (new error codes, updated solutions)
- Technical decisions (current best practices, what replaced X)
- Market/domain knowledge (current state, not 2023 state)
- Anything AI "knows" — verify it has current data

**Research format:**
```
## Research: [What we're researching]

### Sources Checked
- [Source 1]: [URL] — [key finding]
- [Source 2]: [URL] — [key finding]

### Current State (2026)
- [Finding 1]
- [Finding 2]

### Confirmed/Contradicted
- AI said: [what model claimed]
- Reality: [what web search shows]
- Adjustment: [how approach changes based on reality]
```

### Phase 1: Clarify (if vague)
- Auto-detect vague input
- Invoke /office-hours automatically
- Summarize answers as context

### Phase 2: Plan (creates SPEC.md)
- Invoke /autoplan (plan mode)
- Draft SPEC.md (based on research findings)
- Route to user: "SPEC.md ready. Approve to proceed?"

### Phase 3: Implement (phase by phase)
For each task in SPEC.md:
1. Research First (if task involves new external dependency)
2. Execute the task
3. Auto-run /verify against SPEC.md
4. Pass? → next task
5. Fail? → /investigate (3-fix limit) → research error first
6. Still failing? → ESCALATE to user

### Phase 4: Review
- Invoke /review for final sign-off
- Route to user: "Implementation complete. Review findings. Accept?"

### Phase 5: Ship
- Invoke /ship
- Run pre-ship checklist
- Document rollback plan

### Phase 6: Memory + Feedback (after every session)
**This is the active feedback loop — memory STEERS future behavior.**

1. **What happened?** → Record to episodic layer
2. **What worked?** → Extract to semantic layer (use this approach again)
3. **What failed?** → Extract to error-solution layer (avoid this pattern)
4. **User feedback?** → Store explicitly, steer next SPEC based on it
5. **What to do differently?** → Write steering directive for similar tasks

---

## Research-First Principle

**Core rule:** Never assume AI's training data is current. Every claim about:
- "The best way to do X"
- "Library Y has feature Z"
- "API X recently changed"
- "Error Y means Z"

...must be verified via web search before acting on it.

| When | Why | What to Search |
|------|-----|----------------|
| Task involves API | Training data is stale | Current API docs, pricing, limits |
| Task involves library | Version may be old | Latest version, breaking changes |
| Debugging error | New error codes exist | Current error solutions |
| Technical decision | Best practices change | 2026 state of art |
| AI says "typically" | Might be 2022 info | Current industry standard |

---

## Active Memory Steering

### Before Next Workflow — Memory Query

```
Before starting a new workflow:
1. Search past tasks for [similar project type]
2. Extract: "What worked" + "What failed" + "User feedback"
3. Adjust SPEC generation: lean toward what worked, avoid what failed
4. If user previously rejected approach X → try approach Y instead
```

### Steering Directive Format

Stored in ForgeGod after each session:

```markdown
## Steering Directive: [task type]

### What Worked
- Approach: [specific approach that passed easily]
- SPEC style: [verbose/concise, heavy/light verification]

### What Failed
- Pattern: [specific pattern that caused failures]
- Avoid: [what to not do next time]

### User Feedback
- "[Explicit quote from developer on what they wanted different]"
- Apply: [how this should change next SPEC]

### Research Notes
- [Domain]: [what we learned from web research]
- Update approach: [how research changed our method]

### Adjusted Approach
- Next time: [specific change to make]
- Reason: [why this should work better]
```

### Feedback Sources

| Source | What It Tells You |
|--------|------------------|
| SPEC approval/rejection | Was the scope right? Too ambitious? Too narrow? |
| /verify failures | Which criteria were hard to satisfy? |
| /investigate 3-fix limit | Was the implementation approach wrong? |
| User acceptance/rejection | Did output match what they wanted? |
| /review findings | What kept being flagged? |
| Research discoveries | What was AI wrong about? |

---

## Human Checkpoints

Human is consulted ONLY at:
1. **SPEC.md approval** — go/no-go before implementation
2. **Ambiguous decisions** — when spec doesn't cover a case
3. **Irreversible actions** — destructive operations require explicit OK
4. **Final acceptance** — after /review findings
5. **Escalation** — after 3 failed fixes in /investigate

---

## Self-Correction Loop

For each task:
```
Implement → /verify → FAIL?
  → YES: research error first → /investigate → fixes applied → /verify again
  → Still FAIL after 3 attempts → ESCALATE to user
  → PASS: next task
```

---

## TDD Integration

Each implementation phase follows:
1. **Red**: Write failing test for the criterion
2. **Green**: Minimum implementation to pass
3. **Refactor**: Clean up
4. **Verify**: /verify confirms against SPEC.md

---

## Output Format

When complete:
```
## Workflow Complete: [Task]

### Research Findings
- [Domain 1]: [key finding with source]
- [Domain 2]: [key finding with source]

### What Worked
- [specific approach that passed easily]

### What Failed
- [specific pattern that caused failures]

### User Feedback
- "[explicit developer feedback]"

### Memory Updated
- Steering directive stored for [task type]
- Research notes: [domains researched]
- Approach adjusted: [what changes for next similar task]

### Result
**ACCEPTED** — All criteria verified against SPEC.md
```

---

## Anti-Patterns

- Proceeding without SPEC.md → BLOCK
- Skipping research on external dependencies → BLOCK
- Acting on AI claim without verification → BLOCK
- Skipping /verify between phases → BLOCK
- Skipping /review before ship → BLOCK
- Skipping memory update after session → BLOCK
- Accepting "looks good" as evidence → BLOCK
- Bypassing human checkpoints → BLOCK
- Ignoring past steering directives → BLOCK
