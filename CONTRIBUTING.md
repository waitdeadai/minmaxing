# Contributing

PRs are welcome when they improve the open-source core without blurring the
commercial boundary.

## Contribution License

Unless you explicitly state otherwise, any contribution intentionally submitted
to this repository is submitted under Apache-2.0, matching `LICENSE`.

Do not submit code, docs, prompts, data, or generated artifacts that you cannot
license under Apache-2.0.

## Open-Core Boundary

Allowed contributions:

- Harness skills, rules, hooks, scripts, docs, and tests.
- AgentFactory schema improvements and safe dummy blueprints.
- Security, verification, runtime-contract, and least-privilege hardening.
- Bug fixes that keep the public core reproducible and auditable.

Do not include customer data or private commercial artifacts:

- REVCLI private runtime source code, Revis SaaS code, deployment automation, or
  production tenant configuration.
- Customer-specific Hermes agents, private memory seeds, CRM exports, audit
  logs, business-object mappings, or workflow evidence.
- Real credentials, tokens, cookies, API keys, environment values, provider
  configs, or secrets.
- Proprietary sales playbooks, pricing rules, enrichment workflows, connectors,
  or enterprise implementation packs.

## Quality Bar

- Start non-trivial work with a research-backed `SPEC.md`.
- Keep diffs surgical and trace meaningful changes back to the spec or user
  request.
- Run the relevant smoke test and `bash scripts/test-harness.sh` before asking
  for review.
- Do not claim independent verification, memory capture, runtime safety, or
  enterprise readiness unless the artifact proves it.

## Release Checklist

Before merging or tagging public harness work:

- Run `bash scripts/release-check.sh --static-only`.
- Confirm `bash scripts/test-harness.sh` passes locally.
- Confirm `git diff --check` is clean.
- Confirm no private REVCLI/customer assets, credentials, memory seeds, or
  commercial implementation packs are in the diff.
- Confirm runtime claims distinguish static proof from authenticated Claude
  runtime proof.

CI is split into two lanes:

- `harness-static.yml` runs on pull requests and pushes without secrets.
- `harness-runtime.yml` is manual/scheduled and only runs authenticated runtime
  checks when a dedicated `CLAUDE_SETTINGS_JSON` test secret is configured.

## Security

Follow `SECURITY.md`. Do not open public issues for vulnerabilities involving
secrets, customer data, runtime authority, approval bypasses, command escape,
agent escape, system-of-record writes, or kill-switch failures.
