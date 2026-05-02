# Visualization Rules

Use these rules for `/visualize`, `/visualizeworkflow`, and any workflow that
mentions visualization artifacts.

## Core Contract

- `/visualize` creates a comprehension artifact only; it does not implement.
- `/visualizeworkflow` is the approval-first implementation route.
- Plain `/workflow` remains autonomous and must not wait for visual approval
  unless the user explicitly asked for approval-first behavior.
- Visualization artifacts are exploratory unless the user explicitly promotes
  them into product assets.

## Required Inputs

- Read `taste.md` and `taste.vision` before visualization.
- Read active or draft `SPEC.md` when it is relevant to the visualization.
- Do not read `.env`, `.env.*`, `.claude/settings.local.json`, customer data,
  private connectors, audit logs, credentials, or secret files for visual
  context.

## Artifact Modes

Allowed modes:

- `image`
- `prompt-only`
- `markdown`
- `Mermaid`
- `HTML`
- `SVG`

Use image generation only when the current runtime exposes a real image
generation capability. If image generation is unavailable, produce a precise
image prompt, storyboard, schematic, Mermaid, HTML, SVG, or markdown artifact
instead.

## Surface Rules

- Frontend, mobile, product UI, dashboard, game, docs, and brand tasks may use
  image mockups when available.
- Backend API, infra/devtool, and agent-runtime tasks must not be forced into a fake UI mockup. Prefer API experience narratives, operator journeys, architecture diagrams, state flows, or implementation-facing schematics.
- A generated visual should show a plausible shipped artifact or operational
  system, not concept art, unless the user explicitly asked for concept art.

## No Fake Image Claims

Fail the artifact or closeout when it says an image was generated but there is
no image artifact path.

Correct:

- `Mode: prompt-only`
- `Generated Image: none`
- `Image Prompt: prompt.txt`

Incorrect:

- `Generated Image: image.png` when no such file exists
- `Image generated` when only a markdown prompt was written

## Approval Semantics

- `/visualizeworkflow` new and revise runs must stop with
  `WAITING_FOR_VISUAL_APPROVAL`.
- `/visualizeworkflow --continue <run>` is the explicit approval to promote the
  draft spec and implement.
- `/visualizeworkflow --revise <run> ...` updates the visualization package and
  stays stopped.
- Do not mutate root `SPEC.md` or product code during a new or revised
  `/visualizeworkflow` run.

## Required Visualization Package

All generated visualization packages live under ignored `.taste/visualizations/`
and include at minimum:

- `visualization.md`
- source inputs
- Understanding Card
- surface classification
- chosen artifact mode
- artifact paths
- prompt or diagram source
- assumptions
- mismatch risks
- review rubric

For `/visualizeworkflow`, also include:

- `draft-SPEC.md`
- `approval.json`
- `WAITING_FOR_VISUAL_APPROVAL` status before implementation
