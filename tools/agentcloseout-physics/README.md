# AgentCloseout Physics

This directory vendors the Apache-2.0 deterministic closeout engine from
`waitdeadai/agent-closeout-bench` into the public minmaxing harness so daily
Claude Code hooks do not depend on an external checkout or absolute local path.

The engine evaluates Claude Code `Stop` and `SubagentStop` closeout text through
versioned YAML rule packs. It is used by the overlapping closeout hooks:

- `.claude/hooks/govern-effectiveness.sh` for `evidence_claims`
- `.claude/hooks/no-sycophancy.sh`
- `.claude/hooks/no-cliffhanger.sh`
- `.claude/hooks/no-wrap-up.sh`
- `.claude/hooks/no-roleplay-drift.sh`

Run the local wrapper:

```bash
bash scripts/agentcloseout-physics.sh lint-rules tools/agentcloseout-physics/rules/closeout
bash scripts/agentcloseout-physics-smoke.sh
```

ACSP-CC remains a proposed Claude Code closeout profile. Passing any local
conformance or smoke suite is self-assessed preflight evidence, not
certification, not a standard, and not evidence of standard adoption.
