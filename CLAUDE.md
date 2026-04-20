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

## Web Research

- Always web_search before guessing
- Never guess — search first
- Cite sources in responses
- Never guess API behavior or error meanings

## Memory (ForgeGod 5-Tier)

- Run `forgegod audit` before planning
- Persist learnings to obsidian
- Export obsidian notes before session end

## Quick Start

```bash
./scripts/start-session.sh
```

## Session Flow

1. `start-session.sh` → audit, obsidian export, version check
2. User describes goal
3. If vague → /office-hours (6 questions)
4. If new project → /autoplan (generate SPEC.md)
5. If implementation → Execute with PEV loop
6. Before accepting → /verify against SPEC.md
7. Before shipping → /ship checklist

## Effectiveness Metrics

- Every task has a **Pass/Fail** outcome
- No silent successes — verify explicitly
- No ambiguous failures — diagnose clearly
- Vague prompts are a feature, not a bug — /office-hours handles them

## Why This Works

| Pattern | Source | Impact |
|---------|--------|--------|
| Spec-first | Superpowers | Forces clarification |
| Socratic questions | GStack | Reframes vague ideas |
| Verifier agent | Martin Fowler | Prevents confirmation bias |
| PEV loop | Karpathy | Structured quality |
| 3-fix limit | Research | Prevents rabbit holes |
| File isolation | GStack | Parallel without conflicts |
