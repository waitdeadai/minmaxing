# minmaxing - MiniMax 2.7 Harness

## Philosophy: Effectiveness Over Efficiency

**Effective = right results. Efficient = fast results.**

We prioritize getting it right over getting it done fast. Parallel agents done properly with a competent supervisor = guaranteed results.

---

## Core Workflow

1. **SPEC-First**: Every task starts with SPEC.md via /autoplan
2. **10-Agent Parallelism**: Always plan with max parallel agents (10 default)
3. **Supervisor Pattern**: AI supervises workers, not the other way around
4. **Research-First**: Verify AI claims with web search (training data is stale)
5. **Quality Gates**: /verify must pass; tests must pass; no silent failures

## Default Behavior

**When you say "plan this" or "build this":**
1. Supervisor decomposes into 10-agent parallel tasks
2. Workers execute in parallel (up to 10)
3. Supervisor aggregates, verifies, and gates production

**Supervisor's job:** Ensure every task passes verification before declaring done.

## Skills (invoke with /<skill>)
| Skill | Purpose |
|-------|---------|
| /workflow | Autonomous full-implementation loop (10 agents) |
| /audit | Deep codebase audit with 10-agent parallelism |
| /office-hours | Clarify vague ideas |
| /autoplan | Create SPEC.md with 10-agent parallel mindset |
| /verify | Check output against SPEC |
| /review | AI review + human sign-off |
| /qa | Playwright E2E testing |
| /ship | Pre-ship checklist |
| /investigate | Debug with 3-fix limit |
| /sprint | Manual 10 parallel agents |
| /council | Multi-perspective synthesis |
| /browse | Web research with citations |
| /codex | Search code by pattern |
| /overnight | 8hr session with 30-min checkpoints |

## Rules
- **SPEC-First**: No code without SPEC.md
- **10-Agent Default**: Plan with 10 agents always (configurable via MAX_PARALLEL_AGENTS)
- **Keep**: Architecture, security, verification decisions
- **Delegate**: Single-file changes, tests, mechanical refactoring
- **Memory**: Run `forgegod memory` to check learned patterns

## Agent Pool (10 default)
| Hardware | MAX_PARALLEL_AGENTS |
|----------|---------------------|
| 32GB+ RAM, 8+ cores | 10 |
| 16GB RAM, 4+ cores | 6 |
| 8GB RAM, 2+ cores | 3 |

## Quick Start
```bash
./scripts/start-session.sh
```
