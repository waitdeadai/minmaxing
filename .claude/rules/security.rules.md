# Security Rules

## Runtime Profiles

Use explicit profiles instead of implying one permission posture fits every
context.

| Profile | Use Case | Default Mode | Network | Runtime Expectations |
|---|---|---|---|---|
| `solo-fast` | Trusted single-operator local loop | `bypassPermissions` | allowed by local settings | blocks secrets and catastrophic commands |
| `team-safe` | Shared project work | `acceptEdits` | narrower allowlist | governance hooks enabled; bypass mode not recommended |
| `ci-static` | Public static CI | no secrets | no external network | shell syntax, static smokes, evals, diff hygiene |
| `ci-runtime` | Authenticated runtime checks | dedicated test secrets only | isolated temp workspace | runtime smoke, redacted logs, no production credentials |

## Hard Blocks

- Never read `.env`, `.env.*`, `.claude/settings.local.json`, or `secrets/**`
  in normal harness work.
- Never claim `bypassPermissions` is the recommended team default.
- Never run destructive Bash without explicit human approval and rollback
  context.
- Never expose real credentials in fixtures, logs, examples, or generated
  Hermes memory seeds.
- Never treat static CI as proof of authenticated Claude runtime behavior.

## Required Proof

- Profile JSON must parse with `python3 -m json.tool`.
- `solo-fast` and `team-safe` must deny secret reads.
- `team-safe` must use `acceptEdits`.
- Governance hooks must be wired for tool use and closeout events.
- `scripts/security-smoke.sh` must exercise destructive Bash and
  evidence-free closeout fixtures against the governance hook.
