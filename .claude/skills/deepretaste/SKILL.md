---
name: deepretaste
description: Detect product intent, run SOTA-2026 deepresearch with a capacity-bound parallel or hive budget, define ICPs, and bootstrap or propose/apply taste.md, taste.vision, and ICP artifacts. Use when the user invokes /deepretaste or asks to retaste a product from intent and customer research.
argument-hint: [product/context, mode: research|bootstrap|proposal|apply]
disable-model-invocation: true
---

# /deepretaste

Run the intent-to-ICP-to-taste workflow for:

$ARGUMENTS

`/deepretaste` is the high-governance entrypoint for turning an early product
idea or existing repo into a customer-aligned operating kernel.

It is not an independent write path around `/defineicp`. It orchestrates:

- `/deepresearch` for current and stable evidence
- `/hive` only when role-based judgment, blackboard state, dissent, and
  synthesis improve the result
- `/tastebootstrap` when `taste.md` or `taste.vision` are missing
- `/defineicp` for existing-kernel ICP-to-taste proposal or apply semantics

`/deepresearch` remains the general-purpose research engine for architecture,
debugging, benchmarks, provider behavior, market work, product strategy, and
other non-taste investigations. `/deepretaste` uses `/deepresearch` only when
the research is feeding intent, ICP, or taste-kernel decisions.

## Non-Negotiable Contract

- Do not read `.env`, `.env.*`, `.claude/*.local.json`, `secrets/**`,
  credential files, private customer memory seeds, production logs, private
  connector exports, or raw external report bodies unless the user explicitly
  approves the exact source.
- Do not claim "SOTA 2026", "state of the art", "best current practice", or
  "research-backed" unless the claim is backed by a current source ledger or is
  labeled as a stable foundation.
- Use the current `minmaxing temporal anchor` injected by hooks, or run
  `bash scripts/time-anchor.sh text`, before any SOTA 2026, current market,
  competitor, workflow, model, tooling, or benchmark claim. Record the anchor
  date and live-source access dates in the evidence ledger.
- Treat `MAX_PARALLEL_AGENTS`, Codex `max_threads`, and hardware capacity as
  ceilings, not quotas. More lanes are useful only when they reduce
  decision-relevant uncertainty.
- The main agent remains the supervisor. Subagent, hive, worker, or external
  report summaries are claims until parent verification proves them.
- Existing `taste.md` and `taste.vision` are protected kernel files. Do not
  overwrite them from `/deepretaste`.
- If taste files already exist, route all taste mutation through `/defineicp`
  semantics: proposal-first, exact apply approval, backups, hashes,
  changed-line trace, protected-kernel checklist, validation, and rollback.
- If taste files are missing, route kernel creation through `/tastebootstrap`
  semantics: explicit intent intake, 10 kernel questions or equivalent supplied
  answers, both taste files written as a pair, ICP artifact written, and
  validation.
- Block apply when product scope is ambiguous or the approved proposal does not
  name the same product scope.
- Run inline `/introspect pre-plan` before freezing the retaste plan,
  `/introspect pre-apply` before file mutation, and `/introspect pre-closeout`
  before final confidence.

## Mode Selection

- `research`: detect intent, research ICPs, list evidence gaps. No taste patch.
- `bootstrap`: only for missing taste files. Create `taste.md`,
  `taste.vision`, and ICP artifacts using `/tastebootstrap` semantics.
- `proposal`: default for existing kernels. Produce ICP artifacts and taste
  patch proposal using `/defineicp` semantics. No file mutation.
- `apply`: only after explicit approval of an exact proposal id and product
  scope. Use `/defineicp apply` semantics.

If mode is missing, choose:

- `bootstrap` when either taste file is missing and product intent is explicit
  enough
- `proposal` when both taste files exist
- `research` when product scope or intent is ambiguous

## Phase 0: Intent And Kernel Gate

Read safe local truth surfaces first:

1. `taste.md` when present
2. `taste.vision` when present
3. `SPEC.md` when present
4. `.minimaxing/state/CURRENT.md` as stale-prone continuity only
5. `README.md`, product docs, package manifests, app routes, or public docs
   needed to identify the product

Detect and record:

```json
{
  "product_scope": {
    "scope_type": "repo|feature|vertical|distribution|unknown",
    "product": "...",
    "source_evidence": ["user prompt", "README.md", "..."],
    "confidence": "high|medium|low",
    "ambiguities": [],
    "apply_allowed": false
  },
  "intent_detection": {
    "developer_intent": "...",
    "product_intent": "...",
    "route_decision": "research|bootstrap|proposal|apply|blocked",
    "confidence": "high|medium|low"
  },
  "taste_state": {
    "taste_md_exists": true,
    "taste_vision_exists": true,
    "existing_kernel": true
  }
}
```

`apply_allowed` is true only when scope confidence is high and explicit approval
names the same product scope and proposal id.

## Phase 1: Route Arbitration

Use this boundary:

| Need | Route |
| --- | --- |
| Missing `taste.md` or `taste.vision` | `/tastebootstrap` semantics via `/deepretaste bootstrap` |
| Existing taste plus ICP discovery or customer tailoring | `/defineicp` semantics via `/deepretaste proposal/apply` |
| One-week real usage stress test | `/icpweek` |
| Current architecture, debugging, benchmark, provider, market, or product research that will not mutate taste | `/deepresearch` |
| Role-based judgment with dissent and synthesis | `/hive` |
| Disjoint implementation packets | `/parallel` or `/workflow` |

`/deepretaste` must declare which route it is orchestrating and why. Route
confusion blocks file mutation.

## Phase 2: SOTA-2026 DeepResearch Plan

Before the first search wave or synthesis, write:

```markdown
## DeepRetaste Research Plan
- Product Scope:
- Taste State:
- Route Decision:
- Candidate ICPs:
- SOTA Claim Policy:
- Research Branches:
- Effective Parallel/Hive Budget:
- Source Classes:
- Stop Condition:
```

Compute:

```text
effective_deepretaste_budget = min(
  MAX_PARALLEL_AGENTS,
  codex_max_threads,
  hardware_recommended_ceiling,
  distinct_research_lenses_or_hive_roles,
  supervisor_synthesis_capacity,
  verifier_capacity
)
```

Good default lenses:

- `Intent Scout`: product category, workflow, product maturity, constraints.
- `ICP/JTBD Scout`: primary job, urgency, buyer/user distinction, triggers.
- `Market/Current Practice Scout`: current 2026 sources and competitor norms.
- `UX/Product Fit Scout`: adoption friction, trust signals, experience promise.
- `Technical/Ops Scout`: integration, data, reliability, security, support.
- `Skeptic`: false ICP, overbroad segment, fake SOTA, kernel overwrite risk.

Use `/hive` only when the role map needs a visible blackboard, dissent/conflict
log, and synthesis. If using hive, the run must include queen/supervisor,
role map, blackboard claims, dissent log, synthesis, and verification evidence.

Maintain:

```markdown
## Source Ledger
- Cited:
- Reviewed But Not Cited:
- Rejected / Quarantined:
- Conflicts:

## Claim Ledger
| Claim | Label | Evidence | Taste Impact |
| --- | --- | --- | --- |
```

Allowed labels:

- `current-source-backed`
- `stable-source-backed`
- `repo-derived`
- `user-stated`
- `inference`
- `assumption`
- `unknown`

Only `current-source-backed`, `stable-source-backed`, `repo-derived`, or
`user-stated` claims may directly drive taste text. Inferences and assumptions
may drive questions, provisional wording, or blocked status only.

## Phase 3: ICP Synthesis

Produce:

- Primary ICP
- Secondary ICPs only when materially distinct
- Anti-ICP / disqualified segments
- Buyer vs end user distinction
- Job-to-be-done
- Trigger events
- Pain points and desired outcomes
- Current workaround or competitor
- Buying criteria, objections, and proof needed
- Usage frequency and channel
- Technical context and implementation constraints
- Adoption risks
- What the product should optimize for
- What the product should avoid
- Missing evidence and validation questions

Reject generic persona fluff. "Developers who want better tools" is not an ICP
unless it includes a concrete job, urgency, context, trigger, constraints,
disqualifiers, and validation path.

## Phase 4: Kernel Output

### Fresh Bootstrap

Allowed only when `taste.md` or `taste.vision` are missing.

Use the `/tastebootstrap` structure and ensure:

- the 10 kernel questions are answered directly or by clear user/repo evidence
- `taste.md` contains required frontmatter and sections
- `taste.vision` contains required frontmatter and sections
- `.taste/deepretaste/{run_id}/icp.json` records the ICP synthesis
- if one taste file already existed, backup it and preserve compatible content
- `RETASTE_BOOTSTRAPPED` is returned only after validation passes

### Existing-Kernel Proposal

Default when both taste files exist.

Use `/defineicp` proposal semantics and produce:

- ICP artifact under `.taste/deepretaste/{run_id}/icp.json`
- taste patch proposal for `taste.md` and `taste.vision`
- changed-line trace
- protected-kernel checklist
- what not to change
- rollback plan
- validation commands

Stop with:

```text
RETASTE_PROPOSED
```

### Apply

Allowed only when all are true:

- both taste files exist
- product scope confidence is high
- user approval names the exact proposal id
- approval names `taste.md`, `taste.vision`, and the ICP artifact
- current file hashes match the proposal preconditions
- `/introspect pre-apply` has no unresolved blockers

Use `/defineicp apply` semantics:

1. Re-read both taste files.
2. Create backups under `.taste/deepretaste/{run_id}/backups/`.
3. Record pre-change hashes.
4. Write both taste files as one unit.
5. Validate both files.
6. Restore both from backups if validation fails.
7. Record post-change hashes, commands, and rollback path.

Return `RETASTE_APPLIED` only when verification passes.

## Artifact Contract

Every non-trivial run should write a sanitized artifact:

```text
.taste/deepretaste/{run_id}/deepretaste-run.json
```

Required top-level fields:

- `artifact_type: "deepretaste-run"`
- `run_id`
- `mode`
- `status`
- `product_scope`
- `intent_detection`
- `taste_state`
- `routing`
- `research`
- `parallel_decision`
- `icp`
- `kernel_output` or `taste_evolution`
- `taste_mutation`
- `verification`
- `introspection`

Status values:

- `RETASTE_RESEARCHED`
- `RETASTE_DRAFTED_LOW_CONFIDENCE`
- `RETASTE_PROPOSED`
- `RETASTE_WAITING_FOR_APPLY_APPROVAL`
- `RETASTE_BOOTSTRAPPED`
- `RETASTE_APPLIED`
- `RETASTE_BLOCKED`

## Output

```markdown
## DeepRetaste Result
- Status:
- Product Scope:
- Route:
- Taste State:
- Effective parallel/hive budget:
- ICP:
- Kernel action:
- Artifacts:
- Verification:
- Confidence:
- Blockers or next approval needed:
```

## Anti-Patterns

- Replacing `/defineicp` with a second taste-mutation workflow.
- Calling generic web search "SOTA 2026 deepresearch."
- Filling every agent lane because the ceiling is 10.
- Using hive without blackboard, dissent, and verification.
- Applying taste changes from ambiguous product intent.
- Treating worker or subagent summaries as verified truth.
- Bootstrapping over an existing kernel.
