# Security Rules

## Runtime Profiles

Use explicit profiles instead of implying one permission posture fits every
context.

| Profile | Use Case | Default Mode | Network | Runtime Expectations |
|---|---|---|---|---|
| `project-default` | Operator-owned private local loop | `bypassPermissions` | provider-neutral settings; secrets denied | explicit warning, governance hooks, local operator risk |
| `solo-fast` | Trusted single-operator local loop | `bypassPermissions` | allowed by local settings | blocks secrets and catastrophic commands |
| `team-safe` | Shared project work | `acceptEdits` | narrower allowlist | governance hooks enabled; bypass mode not recommended |
| `opusminimax-planner` | Claude subscription planner/reviewer | `acceptEdits` | no MiniMax base URL | Opus model request only; no executor credentials |
| `minimax-executor` | Bounded MiniMax execution packets | `acceptEdits` | MiniMax Anthropic-compatible endpoint | exact `MiniMax-M2.7-highspeed`; packet-only authority |
| `ci-static` | Public static CI | no secrets | no external network | shell syntax, static smokes, evals, diff hygiene |
| `ci-runtime` | Authenticated runtime checks | dedicated test secrets only | isolated temp workspace | runtime smoke, redacted logs, no production credentials |

## Hard Blocks

- Never read `.env`, `.env.*`, `.claude/settings.local.json`, or `secrets/**`
  in normal harness work.
- Never claim `bypassPermissions` is the recommended team default; it is only
  this operator workspace's trusted-local default.
- Never run destructive Bash without explicit human approval and rollback
  context.
- Never expose real credentials in fixtures, logs, examples, or generated
  Hermes memory seeds.
- Never treat static CI as proof of authenticated Claude runtime behavior.
- Never claim `/opusminimax` used Opus unless model identity is verified by
  runtime evidence; planner profiles must not inherit MiniMax base URLs.

## Required Proof

- Profile JSON must parse with `python3 -m json.tool`.
- `.claude/settings.json` must warn that the default is trusted-local
  `bypassPermissions`.
- `solo-fast` and `team-safe` must deny secret reads.
- `team-safe` must use `acceptEdits`.
- Governance hooks must be wired for tool use and closeout events.
- `scripts/security-smoke.sh` must exercise destructive Bash and
  evidence-free closeout fixtures against the governance hook.
