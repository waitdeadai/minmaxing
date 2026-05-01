# Commercial Boundary

minmaxing is open-source infrastructure for governed AI workflows. It is not
the complete commercial service.

## Open-Source Core

The Apache-2.0 public core includes:

- Claude Code harness setup, rules, hooks, and skills.
- `/workflow`, `/deepresearch`, `/introspect`, `/verify`, and `/agentfactory`.
- Public AgentFactory contracts for Hermes agents.
- Public smoke tests and reproducible verification patterns.
- Safe public blueprints and templates with dummy data.

## Private Commercial Moat

The following are private unless a future written decision says otherwise:

- REVCLI private runtime, Revis SaaS code, production deployment automation, and
  managed workflow infrastructure.
- Customer-specific Hermes agents, memory seeds, prompts, audit logs, workflow
  specs, escalation policies, and business-object mappings.
- Enterprise connectors, auth adapters, provider integrations, CRM/Odoo write
  adapters, enrichment workflows, billing, tenant isolation, and monitoring.
- Vertical playbooks for sales, RevOps, support, delivery, finance, recruiting,
  operations, and executive reporting.
- Commercial support, onboarding, implementation, certification, incident
  response, compliance packs, and managed operations.

## What Customers Buy

Customers do not buy "the markdown." Customers buy an operated system:

- Runtime-bound Hermes agents designed for their exact workflows.
- Secure integration with their systems of record.
- Approval gates, audit trails, observability, and kill switches.
- Department-specific workflows with measurable outcomes.
- Deployment, monitoring, training, support, and continuous improvement.

## Public Claims Rule

Public materials may say:

- "minmaxing is an open-source governed AI workflow harness."
- "`/agentfactory` designs reproducible, auditable Hermes agent contracts."
- "Enterprise operation is available as a private managed service."

Public materials must not say:

- "The open-source repo includes the REVCLI managed runtime."
- "The repo can operate an entire company out of the box."
- "Production customer workflows are included."
- "A generated agent is enterprise-ready without runtime evidence, approval
  gates, audit logging, and a tested kill switch."

Commercial inquiries should go through the project maintainer until a dedicated
sales/support channel is published.

## Distribution Boundary

The public repo may ship:

- Installer guidance for Claude Code users.
- Project-scoped Codex defaults and optional `codex-plugin-cc` guidance.
- Static CI, smoke tests, schemas, eval fixtures, and dummy examples.
- Documentation for `solo-fast`, `team-safe`, `ci-static`, and `ci-runtime`
  profiles.

The public repo must not ship:

- Managed-service implementation packs.
- Customer memory seeds or customer-specific Hermes agents.
- REVCLI/Revis private runtime code, tenant infrastructure, or production
  deployment automation.
- Real audit logs, credentials, private connector configs, or commercial
  vertical playbooks.

## Plugin And Installer Claims

Public materials may document how Claude Code, the optional OpenAI Codex plugin,
and local scripts work with the open-source harness. They must not imply that an
installer, plugin, or generated agent includes the private managed runtime or is
production-ready without runtime evidence.

Use dummy examples for public demos. Use private repos or ignored customer
artifact folders for real implementations.
