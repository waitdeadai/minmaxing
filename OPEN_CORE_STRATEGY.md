# Open-Core Strategy

minmaxing is the open-source core for governed AI workflow creation. The
commercial moat is the private managed runtime, customer-specific agent
portfolio, enterprise operations, connectors, memory seeds, deployment
processes, and support that make governed agents useful inside a real company.

This document is an operating boundary for the repository. It is not legal
advice.

## Decision

The public repository is licensed under Apache-2.0 and intentionally exposes:

- The minmaxing harness, skills, rules, smoke tests, and setup scripts.
- The `/agentfactory` workflow for designing Hermes agents as governed,
  runtime-bound operating units.
- Public schemas such as `hermes.manifest.md`, `hermes.runtime.json`,
  `hermes.verify.md`, `hermes.kill-switch.md`, and `hermes-registry.md`.
- Reproducible verification patterns, negative fixtures, and safe example
  blueprints that use dummy data.
- Architecture documents that explain the contract model, taste-first workflow,
  SPEC-first execution, independent verification, and least-privilege design.

The public repository does not include:

- REVCLI private runtime source code, SaaS applications, deployment automation,
  production queues, provider credentials, or tenant configuration.
- Customer-specific Hermes agents, prompts, memory seeds, audit logs, CRM data,
  pricing rules, sales playbooks, operational runbooks, or vertical workflows.
- Private connectors for Odoo, CRMs, email providers, WhatsApp providers,
  payment systems, enrichment APIs, or internal data warehouses.
- Managed service infrastructure, monitoring dashboards, SLO/SLA tooling,
  tenant billing logic, compliance evidence packs, or customer support process.
- "Hermes Enterprise Certified" catalogs, commercial implementation templates,
  or proprietary operating playbooks unless intentionally published later.

## License Posture

Apache-2.0 is the default public license because it is OSI-approved, widely
accepted by enterprise legal teams, includes an explicit patent grant, and
does not pretend to be an anti-competition moat.

Open source cannot honestly restrict commercial use while still being open
source. If a future artifact needs anti-free-riding restrictions, keep it in a
separate private or source-available repository and do not describe that
artifact as open source.

## Moat Boundary

The durable moat is not "a prompt" or a markdown schema. The moat is:

- Runtime execution inside REVCLI/Revis with policy, audit, approval gates,
  queue control, kill switches, and system-of-record adapters.
- Domain-specific Hermes agents tuned for a customer's departments, tools,
  data, escalation policy, and measurable business outcomes.
- Enterprise deployment work: identity, secrets, tenant isolation, observability,
  incident response, retention, procurement, support, and training.
- Private memory scaffolds and failure catalogs learned from real deployments.
- Certification and operating trust: proving an agent is safe, killable,
  scoped, monitored, and accountable in production.

## Public Release Rules

- Public examples must use dummy data, fake credentials, and non-customer
  scenarios.
- A public Hermes blueprint may be read-only or simulated unless the runtime
  bridge, kill switch, and audit evidence are intentionally public.
- Never publish customer names, opportunity IDs, CRM exports, audit evidence,
  enrichment dumps, private prompts, private memory seeds, provider configs, or
  real environment variable values.
- Do not publish REVCLI private implementation details beyond the public
  architectural boundary: REVCLI/Revis is the commercial control plane, Odoo or
  the configured database is the system of record, and Hermes agents route
  side effects through governed runtime actions.
- Public docs must distinguish "can design a governed agent" from "can operate
  your company in production." Production operation is a managed enterprise
  service unless the operator builds and verifies the missing runtime pieces.

## Source Ledger

- Apache Software Foundation: Apache-2.0 is OSI-approved, carries SPDX
  identifier `Apache-2.0`, and includes copyright and patent license grants.
- Open Source Initiative: OSI-approved licenses allow software to be freely
  used, modified, and shared; the Open Source Definition forbids field-of-use
  restrictions such as "no business use."
- GNU/FSF AGPLv3: AGPLv3 is designed for network-server copyleft. It is a valid
  open-source option, but this repo chooses Apache-2.0 to maximize enterprise
  adoption while keeping the commercial runtime private.

## Release Checklist

- [ ] README states the open-core boundary before installation.
- [ ] LICENSE is Apache-2.0 and README badge matches.
- [ ] `COMMERCIAL.md`, `SECURITY.md`, `TRADEMARKS.md`, `NOTICE`, and
      `CONTRIBUTING.md` exist.
- [ ] `.gitignore` excludes customer artifacts, private REVCLI dumps, private
      Hermes bundles, secrets, audit logs, and commercial implementation packs.
- [ ] `bash scripts/test-harness.sh` passes the open-core boundary check.
- [ ] `git diff --check` passes.
