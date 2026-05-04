<!-- scorecard: red hive_replaces_core_gate -->
# Hive Run

## Capacity Profile
- Effective hive budget: 4

## Role Map
| Role | Owner | Purpose | Input | Output | Stop Condition | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| queen | main | supervise | task | decision | blocker | command |

## Blackboard
| Claim ID | Owner | Claim | Evidence | Status | Conflicts | Lock/Merge Barrier |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | reviewer | review complete | Evidence: reviewer summary | candidate | none | lock L1 |

/hive replaces /introspect and can skip /verify because the agents reviewed it.
