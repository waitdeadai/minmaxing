# Dummy Harness Run

This example is intentionally fake. It exists to show public users how a
minmaxing run should be shaped without exposing customer data, private REVCLI
runtime code, commercial playbooks, or credentials.

## Scenario

A dummy repo needs a `status.txt` file that says `ok`.

## Minimal Contract

```markdown
# SPEC: Dummy Status File

## Success Criteria

- [ ] `status.txt` exists.
- [ ] `status.txt` contains exactly `ok`.
- [ ] Verification evidence records the command used to inspect the file.

## Agent-Native Estimate

- Estimate type: agent-native wall-clock
- Execution topology: local
- Effective lanes: 1 of ceiling from `scripts/parallel-capacity.sh --json`
- Critical path: write file -> inspect file -> closeout
- Agent wall-clock: optimistic 1 minute / likely 3 minutes / pessimistic 10 minutes
- Agent-hours: less than 0.25
- Human touch time: none unless reviewing the diff
- Calendar blockers: none
- Confidence: high
```

## Verification

```bash
test "$(cat status.txt)" = "ok"
git diff --check
```

## What This Example Proves

- Public examples should be dummy-only.
- The static harness can be understood without secrets.
- Evidence belongs in commands and artifacts, not in reassurance.

## What This Example Does Not Prove

- Authenticated Claude Code runtime behavior.
- Production readiness.
- Customer workflow correctness.
- REVCLI, Revis, Odoo, CRM, or private connector integration.
