# Runtime Governance Quickstart

minmaxing is Claude Code first. It can also be used from Codex through the
official OpenAI `codex-plugin-cc` plugin or direct Codex CLI defaults, but the
runtime governance surface in this repo is written around Claude Code settings,
hooks, skills, and workflow artifacts.

Use this guide to choose the right profile before running work.

## Profile Matrix

| Profile | Use When | Permission Posture | Proof Command |
|---------|----------|--------------------|---------------|
| `solo-fast` | Trusted local operator, fast iteration, private machine | `bypassPermissions` example with governance hooks and secret/destructive-command guards | `bash scripts/security-smoke.sh` |
| `team-safe` | Shared repo, teammates, reviewers, or client-visible work | `acceptEdits` example with governance hooks and safer defaults | `bash scripts/security-smoke.sh` |
| `ci-static` | Public PRs and no-secret release checks | No runtime credentials, static scripts/evals/docs only | `bash scripts/release-check.sh --static-only` |
| `ci-runtime` | Authenticated smoke/eval in an isolated environment | Explicit credentials from secrets, never default on public PRs | manual `.github/workflows/harness-runtime.yml` |

## Start Local

Run the static local harness first:

```bash
bash scripts/test-harness.sh
```

For release-style static checks without authenticated Claude runtime behavior:

```bash
bash scripts/release-check.sh --static-only
```

These commands must not need production secrets.

## Choose A Claude Code Profile

For shared work, start with the team-safe example:

```bash
cp .claude/settings.team-safe.example.json .claude/settings.local.json
bash scripts/security-smoke.sh
```

For trusted solo local speed, inspect the solo-fast profile first:

```bash
python3 -m json.tool .claude/settings.solo-fast.example.json >/dev/null
bash scripts/security-smoke.sh
```

Do not make `bypassPermissions` the default for teams.

## Runtime Smoke

Authenticated runtime checks are opt-in:

```bash
RUN_CLAUDE_INTEGRATION=1 bash scripts/test-harness.sh
```

Only run this when Claude Code is authenticated locally and the workspace is
safe for runtime tests. Runtime smoke must not run by default on public PRs;
public PRs should rely on static checks. The hosted runtime workflow is manual
and must receive credentials through GitHub secrets, not committed files.

## Codex Users

This repo includes `.codex/config.toml` and `AGENTS.md` so Codex can share the
same project expectations. Codex can inspect, implement, and verify the harness,
but it should respect the Claude Code runtime target:

- Do not describe Codex `max_threads` as Claude Code runtime concurrency.
- Treat Codex subagents as explicit, bounded execution lanes, not a default.
- Use `scripts/parallel-capacity.sh --json` and the active `SPEC.md` before
  estimating or splitting work.
- Keep OpenAI/Codex product questions tied to official OpenAI docs.

## Evidence Before Trust

The harness is not "autonomous because it says so." A run is trustworthy only
when the relevant gates have evidence:

- `SPEC.md` success criteria exist.
- `Agent-Native Estimate` is present for non-trivial planning.
- Worker/subagent outputs are parent-verified.
- Parallel runs aggregate `.taste/parallel/{run_id}` with
  `scripts/parallel-aggregate.sh` when those artifacts exist.
- Verification records commands, metadata, and residual risks.
- Memory claims cite `scripts/memory-eval.sh`, `scripts/memory.sh health`, or
  concrete memory event artifacts.

## Public Boundary

Use dummy examples in this repo. Keep these out of public commits:

- REVCLI/Revis private runtime code.
- Customer Hermes agents or memory seeds.
- Real credentials, audit logs, private connector details, and tenant data.
- Commercial implementation packs and managed-service playbooks.
