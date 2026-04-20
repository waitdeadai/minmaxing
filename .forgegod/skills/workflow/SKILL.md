# /workflow

**THE AUTONOMOUS WORKFLOW** — One command drives the entire implementation loop automatically. AI acts as technical lead, routing to you only at decision points.

**Use when:** User says "build X", "implement Y", "fix Z", or any substantial task.

**Research-backed:** Agent Teams pattern (Planner→Implementer→Tester→Reviewer), TDD loops, Director Mode, Agentic Flywheel.

---

## The Loop (Automated)

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

### Phase 6: Remember (Memory Subagent)
- Extract session outcome → ForgeGod episodic layer
- Extract successful patterns → semantic layer
- Store error→fix pairs → error-solution layer
- Update entity graph → graph layer
- Export to obsidian → cross-session persistence

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

### SPEC.md
/path/to/SPEC.md

### Implementation
- [x] Phase 1: [description] — VERIFIED
- [x] Phase 2: [description] — VERIFIED
- [x] Phase N: [description] — VERIFIED

### Review
/review findings: [summary]

### Ship
/pre-ship checklist: PASS
Rollback plan: [documented]

### Memory
- Episodic: Recorded (task, outcome, duration)
- Semantic: [N] patterns extracted
- Error-Solution: [N] failures → fixes documented
- Obsidian: Exported

### Result
**ACCEPTED** — All criteria verified against SPEC.md
```

---

## Anti-Patterns

- Proceeding without SPEC.md → BLOCK
- Skipping /verify between phases → BLOCK
- Skipping /review before ship → BLOCK
- Accepting "looks good" as evidence → BLOCK
- Bypassing human checkpoints → BLOCK
