<!-- scorecard: red missing_blackboard -->
# Hive Run

## Capacity Profile
- Effective hive budget: 2

## Role Map
| Role | Owner | Purpose | Input | Output | Stop Condition | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| queen | main | supervise | task | decision | blocker | command |

## Verification Evidence
- Command: `bash scripts/hive-scorecard.sh --fixtures --json`
