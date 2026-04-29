# SPEC: Open-Core Moat Boundary

## Purpose

Prepare minmaxing for public open-source release without giving away the
private commercial moat around REVCLI, Revis, customer-specific Hermes agents,
enterprise connectors, operational playbooks, and managed runtime execution.

## Research Brief

Repo evidence:

- `README.md` currently presents minmaxing as a public governed Claude Code
  harness and still advertised an MIT badge.
- `LICENSE` existed but was only a one-line MIT placeholder, not a complete
  license text.
- `CONTRIBUTING.md` only said "PRs welcome" and did not protect against
  private customer artifacts, real secrets, or proprietary REVCLI code.
- `scripts/test-harness.sh` already contract-tests important public claims and
  is the right place to add an open-core boundary regression check.

External source ledger:

- Apache Software Foundation: Apache-2.0 is OSI-approved, carries SPDX
  identifier `Apache-2.0`, includes license application guidance, and includes
  copyright and patent grants.
- Open Source Initiative: OSI-approved licenses allow free use, modification,
  and sharing; the Open Source Definition forbids field-of-use restrictions,
  including business-use restrictions.
- GNU/FSF AGPLv3: AGPLv3 is designed to require source availability for
  modified network-server versions, but this repo prioritizes enterprise
  adoption and keeps the runtime moat private instead of making the OSS license
  anti-commercial.

## Decisions

- Use Apache-2.0 for the public core.
- Do not use source-available or no-commercial terms in this repository because
  that would contradict an open-source positioning.
- Protect the moat by scope, not by pretending an OSS license can block
  competition: REVCLI runtime, customer agents, private memory, connectors,
  vertical playbooks, and managed operations stay out of this repo.
- Add public documents that make the boundary explicit: `OPEN_CORE_STRATEGY.md`,
  `COMMERCIAL.md`, `SECURITY.md`, `TRADEMARKS.md`, `NOTICE`, and an expanded
  `CONTRIBUTING.md`.
- Add `.gitignore` guardrails for private/customer/commercial artifacts.
- Add a harness regression test so public docs cannot drift back to MIT-only,
  unbounded, "everything is included" language.

## Success Criteria

- `README.md` states the open-core boundary before installation and links to
  commercial, security, trademark, and strategy documents.
- `LICENSE` contains complete Apache-2.0 text and `NOTICE` exists.
- `CONTRIBUTING.md` requires Apache-2.0 contributions and forbids private
  REVCLI/customer/secret artifacts.
- `COMMERCIAL.md` explains what is open-source and what remains private.
- `OPEN_CORE_STRATEGY.md` documents why the moat is runtime, service, data,
  connectors, and enterprise operation rather than markdown prompts.
- `SECURITY.md` gives a safe reporting policy and secret/customer-data rules.
- `TRADEMARKS.md` explains brand/certification limits.
- `.gitignore` blocks likely private moat artifacts.
- `scripts/test-harness.sh` includes an open-core boundary check.
- `bash scripts/test-harness.sh`, `git diff --check`, and targeted grep checks
  pass before closeout.

## Non-Goals

- Do not publish private REVCLI source code.
- Do not publish real customer Hermes agents, memory seeds, audit logs, or
  workflow evidence.
- Do not add a CLA/automation system in this pass.
- Do not create sales copy that claims the OSS repo can operate an enterprise
  without runtime integration and verification.

## Changed-Line Trace

- License and NOTICE changes trace to the license-posture decision.
- README and commercial/strategy docs trace to public release readiness.
- CONTRIBUTING, SECURITY, TRADEMARKS, and `.gitignore` changes trace to moat
  protection and safe public collaboration.
- Harness changes trace to regression prevention for the open-core boundary.
