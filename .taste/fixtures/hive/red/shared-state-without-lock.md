<!-- scorecard: red shared_state_without_lock -->
# Hive Run

## Capacity Profile
- Effective hive budget: 3

## Role Map
| Role | Owner | Purpose | Input | Output | Stop Condition | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| queen | main | supervise | task | decision | blocker | command |

## Blackboard
| Claim ID | Owner | Claim | Evidence | Status | Conflicts | Lock/Merge Barrier |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | scout | update memory | Evidence: note | candidate | none | none |

Workers may perform a shared state and registry update from the hive board.
