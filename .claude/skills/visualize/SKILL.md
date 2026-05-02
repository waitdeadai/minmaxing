---
name: visualize
description: Create a taste-to-artifact visualization package for a project, task, draft SPEC, UI, backend, agent runtime, dashboard, game, or product idea without implementing it. Use when the user asks to visualize taste.md, taste.vision, what the model thinks is being built, a product experience, UI mockup, architecture schematic, operator journey, or comprehension check before execution.
argument-hint: [idea, task, SPEC path, or product surface]
disable-model-invocation: true
---

# /visualize

Turn `taste.md`, `taste.vision`, and the current request into an inspectable
comprehension artifact. This skill is for understanding and alignment, not
implementation.

## Contract

- Read `taste.md` and `taste.vision` first.
- If either file is missing, stop and route to `/tastebootstrap`.
- Read `$ARGUMENTS`, active `SPEC.md` when relevant, and obvious public repo
  anchors. Do not read `.env`, `.env.*`, `.claude/settings.local.json`, private
  customer artifacts, credentials, audit logs, or secret files.
- Create one ignored run folder:

```bash
mkdir -p .taste/visualizations
RUN_DIR=".taste/visualizations/$(date +%Y%m%d-%H%M%S)-$(printf '%s' "$ARGUMENTS" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g' | cut -c1-48)"
mkdir -p "$RUN_DIR"
```

- Always write `$RUN_DIR/visualization.md`.
- Do not implement, edit product code, promote assets, commit, push, deploy, or
  mutate `SPEC.md`.
- Keep the package no-secret: do not include credentials, private customer
  artifacts, or raw environment values.

## Understanding Card

Begin `visualization.md` with:

```markdown
## Understanding Card

- Intended user:
- Product promise:
- Core experience:
- Non-goals:
- Visual or operational tone:
- Likely misunderstanding risks:
- Taste anchors:
- Vision anchors:
```

## Surface Classification

Choose exactly one primary surface:

- `frontend-web`
- `mobile-app`
- `backend-api`
- `data-dashboard`
- `game`
- `agent-runtime`
- `infra/devtool`
- `docs/brand`

Record the chosen surface and a one-sentence reason.

## Artifact Choice

- `frontend-web`, `mobile-app`, product UI: produce a production-quality
  UI/product mockup image when the current runtime exposes image generation.
  Use the no-image fallback when image generation is unavailable: write a
  precise image prompt plus an HTML/SVG/Mermaid schematic or UX storyboard.
- `data-dashboard`: produce a dashboard mockup image when available; otherwise
  a chart layout, metric hierarchy, and workflow schematic.
- `game`: produce gameplay screen/key-art prompt when image generation is
  available; otherwise a gameplay loop diagram, screen-state storyboard, or
  interaction map.
- `backend-api`, `infra/devtool`, `agent-runtime`: do not force a fake UI image.
  Produce an operator/user journey map, architecture schematic, state-flow,
  API experience narrative, Mermaid diagram, or HTML/SVG artifact.
- `docs/brand`: produce a brand/page/content system visualization or narrative
  structure.

If an image is generated, save or reference it inside `RUN_DIR` and record the
actual path. If only a prompt, diagram, or markdown artifact is produced, say so
plainly. Never claim an image was generated when it was not.

## Required Sections

`visualization.md` must contain:

```markdown
# Visualization: [short title]

## Understanding Card
## Source Inputs
## Surface Classification
## Chosen Artifact Mode
## Artifact Paths
## Image Prompt Or Diagram Source
## Assumptions
## Mismatch Risks
## Review Rubric
## Outcome
```

The review rubric must check:

- taste alignment
- vision alignment
- user/operator experience clarity
- component or workflow fidelity
- text/label correctness when visual text is involved
- privacy and no-secret posture
- whether the artifact is useful for implementation decisions

## Output

Return a concise summary:

```markdown
## Visualization Complete

- Surface: [classification]
- Mode: [image / prompt-only / markdown / Mermaid / HTML / SVG]
- Run Folder: [.taste/visualizations/...]
- Primary Artifact: [.taste/visualizations/.../visualization.md]
- Generated Image: [path / none]
- Implementation Performed: no
- Open Questions: [none or focused list]
```
