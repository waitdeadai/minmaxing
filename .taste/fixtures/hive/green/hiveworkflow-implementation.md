<!-- scorecard: green -->
# Hive Workflow Run: Dense Implementation

## Task
Coordinate independent docs, scorecard, and verification packets.

## Capacity Profile
- Source: `bash scripts/parallel-capacity.sh --json`
- effective_hive_budget = min(10, 4 roles, 2 supervisor review, 1 verifier, 2 blackboard merge) = 1 for implementation, 3 for research/review.

## Role Map
| Role | Owner | Purpose | Input | Output | Stop Condition | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| queen | main | final synthesis | SPEC.md | closeout | unresolved blocker | `/verify` |
| builder | docs-builder | owned docs packet | README.md | patch evidence | ownership conflict | parent_verified |
| reviewer | skeptic | dissent lane | artifact | blockers | weak evidence | command evidence |
| verifier | test-verifier | run checks | scripts | commands | failure | Exit code |

## Blackboard
| Claim ID | Owner | Claim | Evidence | Status | Conflicts | Lock/Merge Barrier |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | docs-builder | docs updated | Commands Run: `git diff --check` | candidate | needs tests | owned files: README.md |
| C2 | test-verifier | fixtures pass | Command: `bash scripts/hive-scorecard.sh --fixtures --json`; Exit code: 0 | verified | none | merge barrier B1 |

## Dissent And Conflict Log
- Skeptic lane: asked whether `/hive` duplicates `/parallel`; queen rejected that.

## Packet DAG
- P1 docs, P2 scorecard, B1 aggregate, P3 verify.

## Verification Evidence
- Command: `bash scripts/test-harness.sh`
- Exit code: 0

## Outcome
Verified by command evidence, not consensus.
