# /workflow

**THE AUTONOMOUS WORKFLOW** — One command drives the entire implementation loop automatically. AI acts as technical lead, routing to you only at decision points.

**Use when:** User says "build X", "implement Y", "fix Z", or any substantial task.

**Research-backed:** Agent Teams pattern, TDD loops, Director Mode, Agentic Flywheel with active memory feedback.

---

## The Loop (Automated)

### Phase 0: Memory Check (before anything)
- Query ForgeGod for similar past tasks
- What worked? What failed? What did user reject?
- Adjust approach based on past feedback
- If memory has guidance for this task type → apply it

### Phase 1: Clarify (if vague)
- Auto-detect vague input
- Invoke /office-hours automatically
- Summarize answers as context

### Phase 2: Plan (creates SPEC.md)
- Invoke /autoplan (plan mode)
- Draft SPEC.md
- Route to user: "SPEC.md ready. Approve to proceed?"

### Phase 3: Implement (phase by phase)
For each task in SPEC.md:
1. Execute the task
2. Auto-run /verify against SPEC.md
3. Pass? → next task
4. Fail? → /investigate (3-fix limit)
5. Still failing? → ESCALATE to user

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
  → YES: /investigate → fixes applied → /verify again
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

### What Worked
- [specific approach that passed easily]

### What Failed
- [specific pattern that caused failures]

### User Feedback
- "[explicit developer feedback]"

### Memory Updated
- Steering directive stored for [task type]
- Approach adjusted: [what changes for next similar task]
- Error-solution pairs: [N] documented

### Result
**ACCEPTED** — All criteria verified against SPEC.md
```

---

## Anti-Patterns

- Proceeding without SPEC.md → BLOCK
- Skipping /verify between phases → BLOCK
- Skipping /review before ship → BLOCK
- Skipping memory update after session → BLOCK
- Accepting "looks good" as evidence → BLOCK
- Bypassing human checkpoints → BLOCK
- Ignoring past steering directives → BLOCK
