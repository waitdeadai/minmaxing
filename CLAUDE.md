# minmaxing - Ultimate MiniMax 2.7 Harness

## Model
- minimax:2.7-highspeed (100 TPS, 204K context)

## Philosophy: SPEC-FIRST

Every meaningful task begins with SPEC.md. No code, no implementation, no "let's start building" until SPEC exists.

**Why:** Research shows vague prompts without forcing clarification kills effectiveness. SPEC.md forces clarification before building.

### SPEC-First Protocol

1. User describes goal (vague or specific)
2. If vague → Invoke /office-hours (6 forcing questions)
3. Invoke /autoplan to generate SPEC.md
4. SPEC.md is the contract — implementation must match
5. Verify output via /verify before accepting

## Socratic Questioning Mandate

Before assuming, ask. Before building, clarify.

- **Vague prompt** → /office-hours (6 forcing questions)
- **Unclear scope** → Challenge via /autoplan
- **Unverified assumption** → Flag and verify

## PEV Loop: Plan → Execute → Verify

Every task follows PEV:

1. **Plan**: SPEC.md via /autoplan generates clear objectives
2. **Execute**: Implement according to spec
3. **Verify**: /verify agent checks output against spec
4. **Loop**: On failure, diagnose → fix → re-verify

## Quality Gates

- **ESLint error-mode**: warnings are failures, must be fixed
- **Tests must pass**: 100% pass rate, no skipped tests
- **/verify must pass**: before accepting any output
- **No silent failures**: always report status explicitly
- **Circuit breakers**: if quality gate fails, block progression

## Skills (Effectiveness-First)

| Skill | Purpose | When |
|-------|---------|------|
| `/workflow` | **AUTONOMOUS** — drives full loop automatically | "build X", "implement Y", any task |
| `/office-hours` | Reframe vague ideas via 6 forcing questions | "I have an idea", vague prompts |
| `/autoplan` | SPEC-first planning, scope challenge | "plan this", "how do I build" |
| `/verify` | **THE VERIFIER** — checks output against SPEC | After every implementation |
| `/review` | Two-stage: AI review + human sign-off | "review this", PR review |
| `/qa` | Browser testing, Pass/Fail only | "QA this", "test this" |
| `/ship` | Pre-ship checklist, rollback plan | "ship this", "ready to ship" |
| `/investigate` | Hypothesis testing, 3-fix limit | "investigate this", "debug" |
| `/sprint` | 10 parallel agents, FILE ISOLATION | "sprint this", "parallel" |
| `/overnight` | 8hr with 30-min checkpoints | "overnight this", "extended" |
| `/council` | Multi-perspective synthesis | "council this", "architectural" |

## Delegation Rules (80/20)

- **80%** delegating to subagents, macro review
- **20%** architecture, security, quality gating

### Delegate
- Single file changes
- Test writing and execution
- Documentation updates
- Mechanical refactoring
- Bug fixes (with root cause)

### Keep (Never Delegate)
- SPEC.md creation
- Architecture decisions
- Security reviews
- Verification decisions
- Quality gate enforcement

## Context Discipline

- **SPEC.md as reset mechanism**: Fresh context on demand
- **Context rot prevention**: After 50+ turns, consider /compact
- **Sub-agent isolation**: Clean context per agent, no pollution
- **Progressive disclosure**: Current → Project → Memory → Web

## Research-First (NOT Optional)

AI training data is stale. **Every task starts with research** when it involves:
- External APIs or SDKs
- Libraries or frameworks
- Error messages
- Technical decisions
- Best practices claims

**Core rule:** Never assume AI's training data is current. If AI says "recently", "latest", "typically", "best practice" — research it first.

**Research triggers:**
- "the API recently changed..." → verify
- "the latest version of X..." → verify
- "error Y means Z..." → verify (new error codes exist constantly)
- "everyone uses X for Y..." → verify (landscape changes fast)

**Format:**
```
## Research: [Topic]
### Sources
- [URL]: [finding]
### Confirmed/Contradicted
- AI said: [claim]
- Reality: [what web shows]
```

## Memory (ForgeGod 5-Tier)

- Run `forgegod memory` to check what the system has learned
- Persist learnings to obsidian
- Export obsidian notes before session end

## Quick Start

```bash
./scripts/start-session.sh
```

## The Flow

Every task follows this sequence:

1. **You describe what you want** (vague or specific)
2. **If vague → /office-hours** — 6 questions to extract the real problem
3. **/autoplan** — Uses plan mode to create SPEC.md. You approve the plan.
   - `/autoplan` IS plan mode — not a separate thing
   - SPEC.md = source of truth, persists across sessions
4. **Implement** — One task at a time, test after each
5. **/verify** — Separate check against SPEC.md (not the AI that wrote the code)
6. **/review** — You decide whether to accept

**Verification layers:**
- Tool level: auto-format/lint on every edit
- Commit level: tests pass before commit
- SPEC level: /verify checks every meaningful output against spec
- CI level: full test suite before merge

## Effectiveness Metrics

- Every task has a **Pass/Fail** outcome
- No silent successes — verify explicitly
- No ambiguous failures — diagnose clearly
- Vague prompts are a feature, not a bug — /office-hours handles them

## Why This Works

| Pattern | Source | Impact |
|---------|--------|--------|
| Spec-first + plan mode | Addy Osmani, Anthropic | Forces clarity before code |
| Separate verifier | Martin Fowler, research | Prevents confirmation bias |
| 3-fix limit + escalate | 2026 AI coding research | Prevents rabbit holes |
| Small phases + commits | Tyler Burleigh | Save points, not big batches |
| Written artifacts = truth | Addy Osmani | Context persists across sessions |
| Mechanisms > prompts | Harness engineering 2026 | Quality enforced, not requested |
