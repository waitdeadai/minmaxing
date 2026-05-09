---
name: specqa
description: QA every newly created, updated, or reused SPEC.md before implementation using current webresearch for SOTA/time-sensitive claims and an Opus 4.7 high/xhigh reviewer when runtime identity is proven.
argument-hint: [SPEC path or task]
disable-model-invocation: true
---

# /specqa

Run the Spec QA Agent for:

$ARGUMENTS

Spec QA is the automatic quality gate for the active `SPEC.md`.

## Contract

- Spec QA runs after `SPEC.md` is created or updated and before implementation.
- If the spec is reused for a new run, Spec QA still checks that the reused spec
  matches the task before execution begins.
- Use Opus 4.7 high/xhigh reviewer when runtime-proven. Do not claim Opus 4.7 performed Spec QA unless runtime identity evidence proves it through `/status`, a sentinel, or a durable run artifact.
- If Opus 4.7 identity is not proven, record
  `spec_qa_model_identity_status=blocked|unknown` and either continue with
  downgraded confidence or block when the task explicitly requires Opus-only
  judgment.
- Use webresearched actual-time data for SOTA 2026, model/provider behavior,
  prices, laws, security guidance, platform docs, benchmarks, schedules, or any
  claim that could have changed recently.
- Preserve evidence states: `repo-verified`, `web-verified`, `report-derived`,
  `conflicting`, and `unverified`.
- External report claims stay `report-derived` until repo inspection or live
  sources upgrade them.
- Do not read `.env`, `.env.*`, `.claude/*.local.json`, key files,
  credentials, customer memory seeds, or private tokens.

## Inputs

- Active spec path, normally `SPEC.md`.
- User task or workflow artifact context.
- Existing research brief, report intake, code audit, and plan when present.
- Runtime model identity evidence when available.

## Review Passes

1. **Spec identity**
   - Record spec path, SHA-256, task, created/updated/reused status, and
     archive decision.
2. **Model identity**
   - Record requested reviewer model, proven reviewer model if any, proof
     source, and `spec_qa_model_identity_status`.
3. **Current source ledger**
   - For SOTA/time-sensitive claims, run `/webresearch` or the repo's
     `deepresearch` current-source discipline.
   - Record cited sources, reviewed-but-not-cited sources, rejected sources,
     access date, and unresolved uncertainty.
4. **Requirements quality**
   - This requirements quality pass is mandatory for every non-trivial spec.
   - Check clarity, testability, measurable success criteria, acceptance
     coverage, user value, scope boundaries, assumptions, dependencies,
     rollback, and verification plan.
5. **SOTA and product quality**
   - Compare the spec against current best available practice for the domain.
   - Flag stale, generic, underspecified, or quality-degrading instructions.
6. **Security and governance**
   - Check open-core boundaries, no-secret handling, privacy, legal/regulatory
     risk, policy constraints, and no unsupported runtime claims.
7. **Workflow readiness**
   - Confirm the spec can drive a changed-line trace, implementation ownership,
     tests, verification evidence, and rollback.

## Output Artifacts

Write both artifacts for non-trivial file-changing work:

```text
.taste/specqa/{run_id}/spec-qa.md
.taste/specqa/{run_id}/spec-qa.json
```

The Markdown artifact is for humans. The JSON artifact is for smoke gates and
automation.

Minimum JSON fields:

```json
{
  "artifact_type": "spec-qa-result",
  "status": "pass|pass_with_suggestions|fix_required|blocked",
  "decision": "PASS|PASS_WITH_SUGGESTIONS|FIX_REQUIRED|BLOCKED",
  "execution_allowed": false,
  "spec": {
    "path": "SPEC.md",
    "sha256": "...",
    "status": "created|updated|reused"
  },
  "model": {
    "requested_reviewer": "claude-opus-4-7",
    "identity_status": "proven|blocked|unknown",
    "proof_source": "runtime-status|sentinel|artifact|none",
    "claims_opus_review": false
  },
  "current_research": {
    "required": true,
    "sota_target": true,
    "source_ledger": []
  },
  "findings": [],
  "improvement_suggestions": [],
  "artifact_paths": {
    "markdown": ".taste/specqa/{run_id}/spec-qa.md",
    "json": ".taste/specqa/{run_id}/spec-qa.json"
  }
}
```

## Severity And Decisions

- `CRITICAL`: blocks execution. Use `FIX_REQUIRED` or `BLOCKED`.
- `HIGH`: normally blocks unless explicitly downgraded with evidence.
- `MEDIUM`: may pass with suggestions if implementation risk is bounded.
- `LOW`: suggestion only.

Decision rules:

- `PASS`: no findings and no important improvements.
- `PASS_WITH_SUGGESTIONS`: non-blocking findings with concrete improvement
  suggestions.
- `FIX_REQUIRED`: repair the spec before implementation.
- `BLOCKED`: external decision, missing proof, or unresolved current-fact gap
  prevents responsible execution.

## Required Human Report

Use this structure in `spec-qa.md` and workflow artifacts:

```markdown
## Spec QA

- Spec: [path and hash]
- Reviewer requested: claude-opus-4-7 high/xhigh
- Reviewer proven: [yes/no/unknown with proof]
- Decision: PASS | PASS_WITH_SUGGESTIONS | FIX_REQUIRED | BLOCKED
- Current research: [completed/not required/blocked]
- Source ledger: [links and access dates]
- Critical findings: [count]
- Improvement suggestions:
  - [severity] [suggestion] [evidence]
- Execution allowed: [yes/no]
```

## Blocking Conditions

Block execution when:

- critical findings exist
- SOTA/time-sensitive claims lack current webresearch
- Opus 4.7 was claimed without runtime identity proof
- report-derived claims drive requirements without repo/live verification
- success criteria are untestable or not measurable
- security, privacy, legal, or open-core constraints are missing for risky work
- artifact paths or machine-readable JSON are missing
- the spec cannot support changed-line trace and verification evidence

## Anti-Patterns

- Treating Spec QA as a post-implementation review.
- Saying "SOTA" without webresearched actual-time data.
- Claiming Opus 4.7 reviewed the spec from a static request alone.
- Letting `PASS` hide non-critical improvement suggestions.
- Accepting `report-derived` claims as implementation authority.
- Reading secrets to prove provider state.
- Blocking on minor style nits instead of severity and evidence.
