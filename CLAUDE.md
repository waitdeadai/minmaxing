# minmaxing - MiniMax 2.7 Harness

## Core Workflow
1. **SPEC-First**: Every task starts with SPEC.md via /autoplan
2. **PEV Loop**: Plan → Execute → Verify → Loop
3. **Research-First**: Verify AI claims with web search (training data is stale)
4. **Quality Gates**: /verify must pass; tests must pass; no silent failures

## Skills (invoke with /<skill>)
| Skill | Purpose |
|-------|---------|
| /workflow | Autonomous full-implementation loop |
| /office-hours | Clarify vague ideas |
| /autoplan | Create SPEC.md via plan mode |
| /verify | Check output against SPEC |
| /review | AI review + human sign-off |
| /qa | Playwright E2E testing |
| /ship | Pre-ship checklist |
| /investigate | Debug with 3-fix limit |
| /sprint | 10 parallel agents |
| /council | Multi-perspective synthesis |

## Rules
- **SPEC-First**: No code without SPEC.md
- **Keep**: Architecture, security, verification decisions
- **Delegate**: Single-file changes, tests, mechanical refactoring
- **Memory**: Run `forgegod memory` to check learned patterns

## Quick Start
```bash
./scripts/start-session.sh
```
