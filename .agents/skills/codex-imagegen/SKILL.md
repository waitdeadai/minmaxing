---
name: codex-imagegen
description: Generate or edit raster image assets requested by SPEC.md using Codex subscription or ChatGPT-included image generation, not OpenAI API keys. Use when a task, SPEC.md, visualization package, README, landing page, app, game, brand, product demo, or asset manifest asks Codex to create image files, hero images, UI mockups, sprites, diagrams-as-images, thumbnails, or image edits and the operator wants Codex subscription usage instead of API billing.
---

# Codex ImageGen

## Overview

Use this skill when the repo contract asks for actual generated or edited image
assets and the billing/auth path must be Codex subscription usage. This is not
an OpenAI API integration skill.

## Auth And Billing Boundary

- Prefer Codex authenticated with ChatGPT/Codex subscription usage.
- Do not create or run scripts that call the OpenAI Images API or Responses API.
- Do not read `.env`, `.env.*`, local credential files, API keys, tokens, or
  ignored provider profiles to prove access.
- Do not use `OPENAI_API_KEY`, `openai images.generate`, `responses.create`, or
  direct HTTP calls for image generation unless the user explicitly says to use
  API billing instead of subscription usage.
- If the current Codex runtime exposes a native image generation tool, use that
  tool directly.
- If the current runtime has no native image generation tool, fail closed:
  write a prompt/handoff artifact and state that no image was generated.

## Input Contract

Read the active `SPEC.md` first. Also read only task-relevant public assets,
`taste.md`, `taste.vision`, visualization packages, or design docs. Extract an
asset contract for every requested image:

- asset id and purpose
- target path and format, such as `public/hero.webp` or `assets/logo.png`
- dimensions, aspect ratio, background, and transparency needs
- style, brand, visual references, and forbidden elements
- exact text that must appear, or `no embedded text`
- required variants
- acceptance checks

If `SPEC.md` asks for images but lacks output paths or acceptance checks, update
or request a spec clarification before generating.

## Generation Workflow

1. Create an asset manifest in the workflow or task output, listing every image
   to generate or edit.
2. Build a precise prompt for each asset. Include product context, subject,
   composition, lighting, style, dimensions, text constraints, and disallowed
   artifacts.
3. Use the native Codex image generation capability when available. Favor high
   quality for product-facing assets unless the spec explicitly says draft,
   preview, or low cost.
4. Save each generated file to the exact path required by `SPEC.md`. Create
   parent directories as needed.
5. For edits, preserve the original source asset unless the spec explicitly
   allows overwrite. Write edited variants to new paths.
6. Record the revised prompt or final prompt, generated artifact path, and
   generation status.
7. Inspect the output before closeout. At minimum, check file existence, file
   type, approximate dimensions, visible subject, text legibility when relevant,
   and obvious prompt violations.

## Fail-Closed Output

When image generation is unavailable, write a handoff file beside the requested
asset or under the workflow artifact, for example:

```markdown
# Image Generation Handoff: hero

- Status: blocked-no-native-codex-image-tool
- Intended output: public/hero.webp
- Billing mode requested: Codex subscription, not OpenAI API
- Prompt: ...
- Acceptance checks: ...
```

Do not claim the image exists. Do not substitute stock images, SVG placeholders,
CSS gradients, or API-generated images unless the spec explicitly accepts that
fallback.

## Closeout Requirements

Before reporting success:

- every requested generated image has a real artifact path
- each path exists in the workspace or is an attached image artifact that the
  runtime can map to the workspace
- prompts and revised prompts are recorded
- any ungenerated image is marked blocked, not done
- no API keys or secret files were read
