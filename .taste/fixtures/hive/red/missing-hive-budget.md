<!-- scorecard: red missing_hive_budget -->
# Hive Run

## Role Map
| Role | Owner | Purpose | Input | Output | Stop Condition | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| queen | main | supervise | task | decision | blocker | command |

## Blackboard
| Claim ID | Owner | Claim | Evidence | Status | Conflicts | Lock/Merge Barrier |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | main | claim | Evidence: command | candidate | none | lock L1 |
