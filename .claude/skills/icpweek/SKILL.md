---
name: icpweek
description: Run a research-backed ICP week-in-the-life product stress test. Use when the user invokes /icpweek or asks to simulate a full week of real-world product usage by an ideal customer and diagnose product, UX, automation, and technical gaps.
argument-hint: [product/context, mode: full|plan|research|report]
disable-model-invocation: true
---

# /icpweek

Run the ICP week-in-the-life stress test for:

$ARGUMENTS

`/icpweek` turns a product idea, app, workflow, CRM, agent, service, or current repo into a brutally honest one-week simulation from the perspective of:

1. An extremely demanding ideal user trying to use the product in real life.
2. A CTO / Technical CEO evaluating whether the system can operate without friction.
3. A senior product engineer identifying gaps, edge cases, UX failures, technical risks, and improvement opportunities.

The goal is to make the product feel "smooth as butter": reliable, obvious, useful, low-training, and trusted in daily use.

## Non-Negotiable Contract

- Do not produce a superficial review.
- Do not invent product facts. Mark assumptions and unknowns clearly.
- Do not read `.env`, `.env.*`, `.claude/settings.local.json`, `secrets/**`, credentials, customer memory seeds, private connector tokens, or production logs unless the user explicitly approves the exact safe source.
- Use `/deepresearch` discipline before final recommendations when market, competitor, user, workflow, technical, or current-behavior facts materially affect the diagnosis.
- Use `/webresearch` only for narrow current-fact verification; escalate to `/deepresearch` when more than three branches matter or evidence conflicts.
- Use parallel agents or packets only for distinct lenses, research branches, or adversarial review. Treat `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and hardware capacity as ceilings, not quotas.
- Keep the main agent as orchestrator. Worker/subagent findings are claims until the main synthesizes, checks, and cites them.
- Preserve the source prompt's Monday-Sunday simulation and final A-J diagnosis.
- Separate facts, inferences, assumptions, product taste judgments, and implementation recommendations.
- Stop before implementation unless the user explicitly asks to turn findings into code changes, a SPEC, tickets, or a roadmap artifact.

## Intake

Establish the context before analysis:

- Product: what it is, current maturity, live/local/demo status.
- Ideal user: role, daily context, technical level, urgency, buying power.
- User main goal: the job they are trying to complete.
- Main interface/channel: web, app, WhatsApp, Telegram, voice, email, CRM, internal dashboard, API, mixed.
- Expected usage frequency: daily, weekly, intensive, event-driven.
- Desired outcome: what "smooth as butter" means for this product.
- Evidence sources available: repo, docs, demo URL, screenshots, analytics, support notes, operator feedback, research reports.

If essential fields are missing and cannot be inferred from repo/user context, start with an **ICP Week Intake Needed** section and ask only the minimum questions required. If reasonable assumptions are safe, state them and proceed.

## Phase 1: Research Plan

Draft a collaborative research plan before the first external search or final diagnosis:

```markdown
## ICP Week Research Plan
- Product Under Test:
- Ideal User:
- Main Job:
- Interface/Channel:
- Evidence Already Available:
- Research Branches:
- Parallel Budget:
- Source Classes:
- Stop Condition:
```

Use source classes appropriate to the product:

- official product or repo docs
- current domain/industry expectations
- competitor onboarding and workflow patterns
- UX/accessibility/reliability standards
- technical docs for the main interface/channel
- operator feedback, support notes, or screenshots provided by the user

Maintain a source ledger:

```markdown
## Source Ledger
- Cited:
  - [source] - [claim supported]
- Reviewed But Not Cited:
  - [source] - [why downweighted]
- Rejected / Quarantined:
  - [source] - [why not trusted]
- Conflicts:
  - [claim] - [source A vs source B] - [resolution or uncertainty]
```

## Phase 2: Parallel Lenses

Choose the smallest effective lane count:

```text
effective_icpweek_budget = min(
  capacity_recommended_ceiling,
  distinct_lenses_or_research_branches,
  supervisor_review_capacity,
  verification_capacity
)
```

Good default lanes:

- `P1 Ideal User`: lived daily workflow, expectations, emotions, abandonment points.
- `P2 CTO / Technical CEO`: operational smoothness, reliability, permissions, integrations, scalability, observability.
- `P3 Senior Product Engineer`: edge cases, UX ambiguity, data model gaps, automation opportunities, technical risks.
- `P4 Reviewer` optional: challenge assumptions, evidence quality, and overconfident recommendations.

Do not spawn or assign multiple lanes to the same broad question. Do not use all available agents just because capacity exists.

## Phase 3: Week Simulation

Simulate Monday through Sunday. For each day, describe:

1. What the user is trying to accomplish.
2. How the user interacts with the product.
3. What works well.
4. What friction appears.
5. What errors, doubts, blockers, or ambiguities emerge.
6. What edge cases appear.
7. What the user expected to be automatic but was not.
8. What feels slow, confusing, unnecessary, or unnatural.
9. What information is missing for the system to make better decisions.
10. What concrete improvement you would make.

Make the week feel real. Include ordinary interruptions, repeats, forgotten context, ambiguous user intent, low-attention moments, mobile/desktop shifts, notifications, handoffs, retries, errors, and weekend/off-hours behavior when relevant.

## Phase 4: Diagnosis

Deliver the complete diagnosis:

A. The 10 most important product gaps.
B. The 10 moments where the user might abandon the product or feel frustrated.
C. The 10 automations or improvements with the highest impact.
D. The UX problems preventing the product from feeling smooth.
E. The technical or architectural problems that could appear in production.
F. The edge cases most likely to break the system.
G. The features that seem necessary but are still missing.
H. The features that are unnecessary or add avoidable complexity.
I. What must be fixed before selling this to real customers.
J. The ideal version of the product working perfectly in the user's daily life.

Then add:

- `Fastest High-Impact Fixes`: changes that create immediate smoothness.
- `Automation Backlog`: ranked by user impact and implementation risk.
- `Missing Evidence`: facts that would materially change the diagnosis.
- `Do Not Build Yet`: complexity that should wait.
- `Next SPEC Candidates`: only if the user wants implementation planning.

## Output Format

```markdown
# ICP Week: [Product]

## Context
- Product:
- Ideal User:
- Main Goal:
- Interface/Channel:
- Frequency:
- Technical Level:
- Assumptions:

## Research Brief
- Investigation Mode:
- Parallel Budget:
- Research Branches:
- Source Ledger:
- Conflicting Evidence:

## Monday
[10 required daily dimensions]

## Tuesday
[10 required daily dimensions]

## Wednesday
[10 required daily dimensions]

## Thursday
[10 required daily dimensions]

## Friday
[10 required daily dimensions]

## Saturday
[10 required daily dimensions]

## Sunday
[10 required daily dimensions]

## Complete Diagnosis
[A-J]

## Smooth-As-Butter Target State
[the ideal daily-life version]

## Action Priorities
[highest leverage next moves]

## Introspection
- Likely mistakes:
- Evidence checked:
- Assumptions:
- Missing verification:
- Confidence:
```

## Quality Gates

- The daily simulation must include all seven days and all ten daily dimensions.
- The final diagnosis must include A-J.
- Recommendations must be concrete enough to become product changes, tickets, roadmap items, or a SPEC.
- Any source-backed claim must appear in the source ledger.
- Any unsupported claim must be labeled as an inference or assumption.
- If research was blocked, downgrade confidence and say which findings are provisional.
- Run an inline `/introspect pre-final` before closeout: likely mistakes, weak evidence, hidden assumptions, missing user context, overbuilt recommendations, and recommendations that do not follow from the simulated week.

## Anti-Patterns

- Generic persona theater with no daily operational detail.
- Treating the ideal user as patient, trained, or unusually forgiving.
- Ignoring boring repeated tasks, notification fatigue, slow decisions, or data entry.
- Calling something "automatic" when it still requires hidden human work.
- Recommending features without saying what user moment they fix.
- Flattening the CTO and product-engineer lenses into generic UX feedback.
- Filling the parallel budget for appearance.
- Producing a roadmap without first naming what must be fixed before selling.
