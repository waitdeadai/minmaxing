<!-- scorecard: red linear_hive_scaling -->
# Hive Run

## Capacity Profile
- Effective hive budget: 10

## Role Map
| Role | Owner | Purpose | Input | Output | Stop Condition | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| queen | main | supervise | task | decision | blocker | command |

## Blackboard
| Claim ID | Owner | Claim | Evidence | Status | Conflicts | Lock/Merge Barrier |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | main | use all agents | Evidence: plan | candidate | none | lock L1 |

10 agents means 10x faster.
