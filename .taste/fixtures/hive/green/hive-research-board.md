<!-- scorecard: green -->
# Hive Run: Broad Repo Audit

## Task
Audit independent repo surfaces with scouts and a reviewer.

## Capacity Profile
- Source: `bash scripts/parallel-capacity.sh --json`
- Effective hive budget: 3 of ceiling 10
- Reason: two scout lanes plus one reviewer lane are useful; verifier capacity
  is one lane.

## Role Map
| Role | Owner | Purpose | Input | Output | Stop Condition | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| queen | main | supervise scope and synthesis | SPEC.md | decision log | blocker | command evidence |
| scout | repo-scout | inspect workflow surfaces | .claude/skills | source ledger | stale context | cited files |
| reviewer | risk-reviewer | challenge plan | diff and spec | risk table | unresolved risk | parent check |

## Blackboard
| Claim ID | Owner | Claim | Evidence | Status | Conflicts | Lock/Merge Barrier |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | repo-scout | workflow owns lifecycle | `.claude/skills/workflow/SKILL.md` | verified | none | owned files: docs only |
| C2 | risk-reviewer | consensus needs tests | `scripts/test-harness.sh` | verified | none | merge barrier B1 |

## Dissent And Conflict Log
- Skeptic lane: reviewer challenged any consensus without command evidence.
- Arbitration: queen accepted only repo-verified claims.

## Synthesis And Arbitration
Consensus is advisory; queen uses evidence and verification.

## Verification Evidence
- Command: `bash scripts/hive-scorecard.sh --fixtures --json`
- Exit code: 0

## Outcome
PASS with medium confidence.
