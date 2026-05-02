---
name: visualizeworkflow
description: Run an approval-first variant of the minmaxing workflow: research, audit, plan, estimate, draft SPEC, visualize the intended product or operator experience, then stop with WAITING_FOR_VISUAL_APPROVAL before implementation. Use when the user wants to see and approve the model's understanding before code changes, or wants to continue or revise a saved visualization workflow.
argument-hint: [task] | --continue .taste/visualizations/<run> | --revise .taste/visualizations/<run> [revision]
disable-model-invocation: true
---

# /visualizeworkflow

Approval-first workflow for visual or experiential alignment. Plain `/workflow` remains autonomous; this command is the opt-in approval route.

## Modes

### New Run

Use for:

```text
/visualizeworkflow "build the dashboard"
```

Run the normal governed planning spine inline:

1. Taste gate: read `taste.md` and `taste.vision`; if missing, stop and route
   to `/tastebootstrap`.
2. Research brief: use the repo's effectiveness-first deepresearch protocol
   when current facts matter; justify local-only when they do not.
3. Code audit: inspect relevant repo anchors before planning.
4. Introspection: run `pre-plan` hard-gate reasoning before freezing the draft.
5. Plan and Agent-Native Estimate.
6. Draft `SPEC.md` into the visualization run folder as `draft-SPEC.md`.
7. Create the visualization package using the `/visualize` contract inline.
8. Stop before implementation.

Do not mutate product code or root `SPEC.md` during a new run. The draft spec
stays under `.taste/visualizations/{run}/draft-SPEC.md` until approval.

### Continue

Use for:

```text
/visualizeworkflow --continue .taste/visualizations/YYYYMMDD-HHMMSS-slug
```

This means the user approves the saved visualization enough to implement.

1. Read `visualization.md`, `draft-SPEC.md`, and `approval.json`.
2. Check live `git status`, active `SPEC.md`, and obvious repo drift since the
   artifact was created.
3. Archive a non-reused active `SPEC.md` before replacing it.
4. Promote `draft-SPEC.md` to root `SPEC.md`.
5. Execute the implementation inline using `/workflow` rules as the playbook,
   but do not rely on nested custom-skill chaining.
6. Verify against root `SPEC.md`, run post-implementation introspection, archive
   closeout, and summarize.

### Revise

Use for:

```text
/visualizeworkflow --revise .taste/visualizations/YYYYMMDD-HHMMSS-slug "make it denser"
```

Update `visualization.md`, `draft-SPEC.md`, and `approval.json` with the
revision request. Stay stopped with `WAITING_FOR_VISUAL_APPROVAL`. Do not
implement.

## Run Folder

All new and revised artifacts live under ignored `.taste/visualizations/`:

```text
.taste/visualizations/YYYYMMDD-HHMMSS-slug/
  visualization.md
  draft-SPEC.md
  approval.json
  prompt.txt              # when an image prompt is produced
  diagram.md|html|svg     # when a schematic is produced
  image.png|webp|jpg      # only when an image is actually generated
```

`approval.json` must be valid JSON:

```json
{
  "status": "WAITING_FOR_VISUAL_APPROVAL",
  "task": "short task",
  "surface": "frontend-web",
  "mode": "image|prompt-only|markdown|Mermaid|HTML|SVG",
  "root_spec_promoted": false,
  "implementation_started": false,
  "created_at": "ISO-8601 or unknown",
  "updated_at": "ISO-8601 or unknown"
}
```

On continue, update status to `APPROVED_FOR_IMPLEMENTATION` before implementing
and to `IMPLEMENTED_VERIFIED` after verification.

## Approval Stop Output

Every new or revised run must end with:

```markdown
## Visual Approval Required

- Status: WAITING_FOR_VISUAL_APPROVAL
- Run Folder: .taste/visualizations/...
- Visualization: .taste/visualizations/.../visualization.md
- Draft SPEC: .taste/visualizations/.../draft-SPEC.md
- Implementation Started: no

Approve and continue:
/visualizeworkflow --continue .taste/visualizations/...

Revise:
/visualizeworkflow --revise .taste/visualizations/... "requested change"
```

## Hard Rules

- `/visualizeworkflow` is the approval route; `/workflow` remains autonomous.
- Never implement before `--continue`.
- Never claim an image exists unless an image artifact path exists.
- Backend, API, infra, and agent-runtime tasks may use diagrams or operational
  narratives instead of fake UI mockups.
- Do not read or persist secrets, private customer artifacts, or `.env` files.
