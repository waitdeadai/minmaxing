# Security Policy

minmaxing is a workflow harness that can shape powerful autonomous agent
systems. Treat issues involving credentials, runtime authority, generated
agents, memory seeds, audit logs, and customer data as security-sensitive.

## Supported Versions

Security fixes target the latest `main` branch unless a maintained release
branch is explicitly listed in this file.

## Reporting A Vulnerability

Do not open a public issue for vulnerabilities involving secrets, private
customer data, bypassable approval gates, unsafe command execution, agent
escape, runtime privilege escalation, or kill-switch failure.

Preferred reporting path:

- Use GitHub private vulnerability reporting for this repository when enabled.
- If private reporting is unavailable, contact the maintainer privately through
  the GitHub profile and include only the minimum detail needed to coordinate a
  safe disclosure path.

Include:

- A concise description of the issue and affected files.
- Reproduction steps using dummy data.
- Expected impact and whether credentials, customer data, external side
  effects, or system-of-record writes are involved.
- Suggested mitigation, if known.

Do not include:

- Real API keys, tokens, passwords, session cookies, customer exports, CRM
  records, audit logs, or private Hermes memory seeds.
- Exploit automation against third-party systems.

## Security Baseline

Public contributions and generated examples must preserve these rules:

- No real secrets in git.
- Least-privilege tool grants for Hermes agents.
- Runtime actions must declare authority, approval gates, audit events,
  idempotency keys, and kill switches.
- REVCLI/Revis-facing agents must route side effects through the governed
  runtime control plane instead of direct unmanaged system-of-record writes.
- Public examples must use fake data and safe simulated runtime evidence.

## Runtime Policy Matrix

minmaxing supports multiple runtime profiles. Do not blur them together.

| Profile | Intended Use | Permission Mode | Network / Secrets | Required Proof |
|---|---|---|---|---|
| `solo-fast` | Trusted single-operator local loop | `bypassPermissions` | local operator responsibility; secrets still denied by settings | valid JSON, secret deny rules, governance hook smoke |
| `team-safe` | Shared project and collaborator work | `acceptEdits` | narrower allowlist; no broad side effects by default | valid JSON, governance hooks, no bypass default |
| `ci-static` | Public CI and pull requests | static only | no secrets, no external network requirement | shell syntax, static smokes, eval pack, diff hygiene |
| `ci-runtime` | Authenticated runtime validation | isolated test workspace | dedicated test credentials only, redacted logs | explicit runtime smoke with no production secrets |

bypassPermissions is not the recommended team default. It is a trusted-local
speed profile for a single operator who understands the repo and accepts the
local risk. Team and CI contexts should prefer `team-safe`, `ci-static`, or
`ci-runtime` depending on whether runtime credentials are intentionally present.

## Out Of Scope

- Vulnerabilities in private REVCLI deployments that are not present in this
  public repository.
- Social engineering, physical attacks, denial-of-service tests, or attacks
  against third-party services.
- Reports that require real customer data or production credentials to verify.
