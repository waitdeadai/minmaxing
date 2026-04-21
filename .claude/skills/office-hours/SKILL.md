# /office-hours

YC-style startup diagnostic that reframes vague ideas into buildable specs. Uses 6 forcing questions to expose demand reality, status quo, desperate specificity, narrowest wedge, observation, and future-fit.

**Use when:** User says "I have an idea", "brainstorm this", "is this worth building", "help me think through", "swarm", "swarm this", or when a prompt is too vague to spec.

**Proactively invoke when:** Vague goals are described — never skip to implementation.

---

## Purpose

Transform vague ideas into buildable SPECs. The 6 questions are forcing functions — they make you confront assumptions you've been avoiding.

**Hard gate:** This skill produces design docs only. No implementation, no code, no scaffolding. Skipping questions = skipping the exam.

---

## Execution Protocol

### Pre-Check: Verify Vagueness

If user's description is already specific with clear scope, skip to SPEC generation via /autoplan.

If vague → proceed with 6 questions, one at a time.

---

### The 6 Forcing Questions

Present one question at a time. Wait for answer before proceeding.

---

#### Question 1: Demand Reality

**"Have you personally talked to 10 people who have this problem?"**

- If NO → "Go talk to them first. Ideas without real feedback are speculation."
- If YES → Document what you learned

**Follow-up:** "What did they actually say? Exact quotes or paraphrased?"

---

#### Question 2: Status Quo

**"What's the current solution everyone uses?"**

- If unclear → "Most ideas are improvements on existing solutions. What would someone do TODAY if your solution didn't exist?"
- Document current workaround

**Follow-up:** "Why haven't they switched yet? What's the switching cost?"

---

#### Question 3: Desperate Specificity

**"What specifically breaks today? Show me the error message, the workflow, the exact moment."**

- If vague ("it doesn't work well") → Press for specifics
- If specific → Document exact failure mode

**Follow-up:** "If I watched you for 30 minutes, at what minute would I see the problem?"

---

#### Question 4: Narrowest Wedge

**"What's the 20% of this that would solve 80% of the problem?"**

- Force a single, concrete feature
- If multiple features → "Pick one. Which has highest impact with lowest effort?"

**Follow-up:** "If you could only ship ONE thing, what would it be?"

---

#### Question 5: Observation

**"Have you experienced this problem yourself? When?"**

- If NO → "Building something for users you don't understand is risky."
- If YES → Document your personal experience

**Follow-up:** "What did you try first? What worked?"

---

#### Question 6: Future-Fit

**"Imagine this ships. 6 months later, what's broken?"**

- Force honest post-mortem thinking
- If no answer → "You don't know your own product."

**Follow-up:** "What would you do differently if you knew what you know now?"

---

## Output Format

After all 6 questions are answered:

```markdown
## Office Hours: [Project Name]

### Demand Signal
- [x] Talked to 10 people / [ ] Needs validation
- Key insight: "[quote or summary]"

### Current Solution
- Status quo: [what people do today]
- Switching cost: [why they haven't changed]

### Specific Problem
- Exact failure mode: [specific description]
- When observed: [minute N of the workflow]

### Narrowest Wedge
- Single feature: [one sentence]
- Impact vs effort: [high/medium/low]

### Founder Fit
- [x] Experienced personally / [ ] User research required
- Personal experience: [your story]

### Future Risks
- 6-month failure mode: [what breaks]
- Lesson learned: [what you'd do differently]

## Recommendation
- **[BUILD]** — Strong signal on 4+ questions
- **[RESEARCH]** — Needs more validation
- **[PIVOT]** — Wrong problem, consider alternatives

## Next Step
If BUILD: invoke /autoplan to generate SPEC.md
If RESEARCH: Define 3 specific questions to answer first
If PIVOT: Explore [adjacent problem] instead
```

---

## Quality Gates

- All 6 questions must be answered (no skipping)
- Answers must be specific (not "maybe", "probably", "I think")
- Recommendation must match the evidence
- If RESEARCH: specific questions must be listed
- If PIVOT: alternative must be suggested
- This skill produces DESIGN DOCS only — no code

---

## Anti-Patterns

- Answering questions yourself instead of the user → FAIL
- Accepting vague answers → FAIL, press harder
- Skipping questions because "they don't apply" → FAIL
- BUILD recommendation without demand validation → FAIL
- Producing code/implementation instead of analysis → BLOCK
