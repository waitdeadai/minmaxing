---
name: defineicp
description: Define the ICP or ICPs for the current product with deepresearch, then draft or apply ICP-driven updates to taste.md and taste.vision. Use when the user invokes /defineicp or asks to tailor the product kernel to ideal customer profiles.
argument-hint: [product/context, mode: research|proposal|apply]
disable-model-invocation: true
---

# /defineicp

Run the ICP-to-taste evolution workflow for:

$ARGUMENTS

`/defineicp` defines the ideal customer profile or profiles for the product the
developer is building, then retroaliments the project kernel by drafting
ICP-aligned changes to `taste.md` and `taste.vision`.

This command is not a persona generator. It is a governed taste-evolution
workflow: deepresearch first, ICP synthesis second, taste patch proposal third,
and file rewrite only with explicit apply approval.

## Non-Negotiable Contract

- Do not read `.env`, `.env.*`, `.claude/*.local.json`, `secrets/**`,
  credential files, customer private memory seeds, production logs, or private
  connector exports unless the user explicitly approves the exact source.
- Do not invent ICP certainty. Separate facts, source-backed claims,
  repo-derived evidence, user-stated claims, inferences, assumptions, unknowns,
  and contradictions.
- Do not overwrite `taste.md` or `taste.vision` silently.
- Default mode is proposal-first. Produce the ICP artifact and taste patch
  proposal, then stop with `ICP_DRAFTED`.
- Apply mode requires explicit user approval for the exact proposed rewrite.
- Preserve the protected kernel unless the user explicitly approves each
  invariant change:
  - SPEC-first
  - research-first
  - evidence-backed verification
  - explicit and stable contracts
  - single-owner state validated at boundaries
  - structured and explainable errors
  - observable operations
  - least privilege and explicit privacy boundaries
  - reversible rollback
  - separate verifier with concrete evidence
  - no silent destructive behavior
- If applying, backup both taste files, record pre-change hashes, update both
  files as one unit, validate both files, and record rollback instructions.
- Use `/deepresearch` discipline before final ICP decisions when market,
  customer, competitor, buyer, workflow, pricing, technical-context, or current
  behavior facts materially affect the outcome.
- Use `/webresearch` only for narrow current-fact checks. Escalate to
  `/deepresearch` when more than three branches matter, evidence conflicts, or
  the findings will drive taste rewrites.
- Use parallel agents or packets only for distinct research lenses. Treat
  `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and hardware capacity as ceilings,
  not quotas.
- Keep the main agent as orchestrator. Subagent, worker, or external report
  findings are claims until the main verifies and cites them.
- Run inline `/introspect pre-final` before final report, and
  `/introspect pre-apply` before changing `taste.md` or `taste.vision`.

## Mode Selection

- `research`: define ICP candidates and evidence gaps. No taste patch.
- `proposal`: default. Define ICPs and produce a full taste patch proposal. No
  file mutation.
- `apply`: only after explicit user approval. Rewrite `taste.md` and
  `taste.vision` from the accepted proposal, with backups and verification.

If mode is missing, use `proposal`.

## Phase 0: Taste And Scope Gate

Read these before planning:

1. `taste.md`
2. `taste.vision`
3. `SPEC.md` when present
4. `.minimaxing/state/CURRENT.md` as a stale-prone continuity hint
5. `README.md` or product docs when needed to identify the product

Decide the product scope:

- repo-level product
- feature or slash-command surface
- customer vertical
- target distribution or deployment

Block apply if product scope is ambiguous. Ask the minimum question needed or
continue in `research` mode with the ambiguity clearly labeled.

## Phase 1: ICP Intake

Collect or infer:

- Product and maturity
- Current users and buyer/user distinction
- Main job-to-be-done
- Urgent pain or desired outcome
- Current workaround or competitor
- Trigger event that makes the user seek a solution
- Budget, authority, procurement, and switching constraints
- Technical level and implementation environment
- Usage frequency and primary channel
- Geography, industry, company size, role, or segment constraints
- Retention, referral, or expansion signals
- Anti-ICP / disqualifiers
- Evidence sources available

If the user already supplied enough context or repo evidence is strong, proceed
with labeled assumptions instead of asking a long questionnaire.

## Phase 2: DeepResearch Plan

Before the first search wave or final synthesis, write:

```markdown
## DefineICP DeepResearch Plan
- Product Scope:
- Product Under Definition:
- Existing Taste Kernel:
- Candidate ICPs:
- Research Branches:
- Effective Parallel Budget:
- Source Classes:
- Stop Condition:
```

Compute:

```text
effective_defineicp_budget = min(
  MAX_PARALLEL_AGENTS,
  codex_max_threads,
  hardware_recommended_ceiling,
  distinct_research_lenses,
  supervisor_synthesis_capacity,
  verification_capacity
)
```

Good default lenses:

- `P1 Highest-Value User`: job, urgency, repeated workflow, emotional stakes.
- `P2 Economic Buyer`: budget, trigger, authority, objections, proof needed.
- `P3 Product/UX Fit`: expectations, moments of friction, adoption barriers.
- `P4 Technical Fit`: integrations, data, reliability, security, operations.
- `P5 Adversarial Reviewer`: weak claims, false ICPs, overfit segments.

Do not fill all available lanes unless each lane reduces decision-relevant
uncertainty.

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

Maintain a claim ledger:

```markdown
## ICP Claim Ledger
| Claim | Label | Evidence | Taste Impact |
|-------|-------|----------|--------------|
| ... | source-backed / repo-derived / user-stated / inference / assumption / unknown | ... | ... |
```

Only `repo-derived`, `user-stated`, or strong `source-backed` claims may drive
direct taste changes. Inferences and assumptions may guide questions or
provisional language only.

## Phase 3: ICP Synthesis

Produce:

- Primary ICP
- Secondary ICPs, only if materially distinct and actionable
- Anti-ICP / disqualified segments
- Buyer vs end user distinction
- Job-to-be-done
- Trigger events
- Pain points and desired outcomes
- Buying criteria and objections
- Required proof or trust signals
- Product expectations
- Channel and adoption context
- Technical constraints
- What the product should optimize for
- What the product should avoid for this ICP
- Validation questions and missing evidence

Reject generic persona fluff. "Startup founders who want growth" is not an ICP
unless it includes a concrete job, urgency, budget/authority, channel, pain,
trigger, disqualifiers, and validation path.

## Phase 4: Taste Evolution Proposal

Draft changes to both files:

- `taste.md`: map ICP findings into design principles, experience and
  interaction, interface contracts, system behavior, architecture, naming, and
  do/don't guardrails.
- `taste.vision`: map ICP findings into intent, audience, success criteria,
  non-goals, values, tradeoffs, and experience promise.

Every proposed hunk must have a changed-line trace:

```markdown
| File/Section | Proposed Change | Source Claim | Label | Rationale |
|--------------|-----------------|--------------|-------|-----------|
| taste.md / Experience & Interaction | ... | C12 | source-backed | ... |
```

Also include:

- Protected kernel checklist
- Removed or softened language with rationale
- What not to change
- Rollback plan
- Validation commands

Stop here in `proposal` mode:

```text
ICP_DRAFTED
```

## Phase 5: Apply Mode

Apply only when the user explicitly approves the exact proposal. A vague "looks
good" is not enough if the proposal changed protected kernel invariants.

Before writing:

1. Re-read `taste.md` and `taste.vision`.
2. Reconcile the accepted proposal with current file hashes.
3. Create timestamped backups under `.taste/defineicp/{run_id}/backups/`.
4. Record pre-change hashes.
5. Run `/introspect pre-apply`.

Write both files as one unit. If either file fails validation, restore both from
backup.

After writing:

- Validate required frontmatter and section headings.
- Validate protected kernel preservation.
- Run focused static checks available in the repo.
- Record post-change hashes, commands, and rollback path.
- Return `ICP_APPLIED` only when verification passes.

Return `ICP_BLOCKED` if:

- product scope is ambiguous
- source ledger is missing when external facts matter
- claims are unlabeled
- the patch weakens security, privacy, rollback, verification, or non-goals
  without explicit approval
- backups or hashes are missing in apply mode
- verification fails

## Output Format

```markdown
# DefineICP: [Product]

## Context
- Product Scope:
- Product:
- Existing Taste Kernel:
- Mode:
- Assumptions:

## DeepResearch Brief
- Investigation Mode:
- Effective Parallel Budget:
- Research Branches:
- Source Ledger:
- Conflicting Evidence:

## ICP Candidates
- Primary ICP:
- Secondary ICPs:
- Anti-ICP / Disqualified Segments:

## ICP Claim Ledger
[claim table]

## Product Implications
- Experience:
- Interface:
- System Behavior:
- Trust / Proof:
- Adoption:
- Non-Goals:

## Taste Evolution Proposal
- Protected Kernel Checklist:
- Proposed `taste.md` Changes:
- Proposed `taste.vision` Changes:
- Changed-Line Trace:
- What Not To Change:

## Apply Plan
- Approval State:
- Backup Paths:
- Pre-Change Hashes:
- Validation Commands:
- Rollback:

## Verification
- Structural Checks:
- Semantic Preservation:
- Command Evidence:

## Introspection
- Likely mistakes:
- Evidence checked:
- Assumptions:
- Missing verification:
- Confidence:

## Status
ICP_DRAFTED / ICP_APPLIED / ICP_BLOCKED
```

## Quality Gates

- Primary ICP must include job-to-be-done, pain, trigger, budget/authority or
  buyer context, adoption channel, objections, proof needed, and disqualifiers.
- Anti-ICP must be present.
- Source ledger and claim ledger are required when external facts matter.
- Recommendations must be mapped to taste sections, not left as generic
  marketing copy.
- Protected kernel checklist must be present before any taste rewrite.
- Proposal mode must not mutate files.
- Apply mode must record explicit approval, backups, hashes, changed-line trace,
  validation commands, and rollback path.
- `ICP_APPLIED` is forbidden after failed verification.
- Inline `/introspect` must downgrade confidence when evidence is weak.

## Anti-Patterns

- Rewriting the project kernel into a sales persona.
- Treating ICP as demographics without job, urgency, or buying context.
- Calling assumptions facts because they sound plausible.
- Copying market claims into `taste.md` without a source ledger.
- Deleting non-goals, security, rollback, or verification language because it
  feels less ICP-specific.
- Skipping anti-ICP/disqualifiers.
- Filling every parallel lane for show.
- Claiming the product is tailored without showing the exact accepted taste diff.
