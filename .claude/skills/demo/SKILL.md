---
name: demo
description: Produce governed recorded product demos with bilingual voiceover, captions, browser evidence, safety gates, and artifact manifests.
argument-hint: [product route, app path, or demo objective]
disable-model-invocation: true
---

# /demo

Generate or validate a recorded product demo for:

$ARGUMENTS

`/demo` is a governed media-producing route. It is not a marketing-prompt shortcut and not a hidden mode of `/visualize`. It may consume `/visualize` or `/visualizeworkflow` artifacts, but it must keep `/visualize`'s no-implementation/no-mutation promise intact.

Use `/demo` when the operator wants a product-tour demo, sales demo, QA demo, or internal workflow recording that shows what the product actually does and can be trusted as evidence. The default language package is English plus well-spoken neutral Spanish.

When `/demo` creates or updates repo-tracked scripts, fixtures, docs, manifests,
or demo routes, `/opusworkflow` is the default outer route and `/demo` is the
inner contract. Direct `/demo` invocation remains valid, but file-changing work
must inherit the Claude/Opus planner-reviewer plus MiniMax-M2.7-highspeed
executor policy.

```text
outer_route: opusworkflow
inner_contract: demo
```

## Non-Negotiable Contract

- Start with research and repo inspection before storyboard, capture, or narration.
- Record only an explicitly provided local, preview, or approved demo URL.
- Browser recordings must use an ephemeral browser context with no persistent user profile, no imported cookies, no saved `storageState`, no password manager, and no personal Chrome or Chromium profile path.
- The `/demo` recording lane must never read `.env`, `.env.*`, `.claude/settings.local.json`, `secrets/**`, shell environment dumps, or provider tokens.
- Required non-secret options must be passed as explicit CLI flags or a checked-in example config with placeholder values.
- Generated recordings, screenshots, traces, audio, rendered video, and manifests are local transient artifacts.
- Write generated outputs only under `.taste/demo-recordings/{run_id}/` or another explicitly ignored output directory.
- Do not commit binary media. Commit only small sanitized manifests or fixtures when a test requires them.
- Use deterministic browser automation first. Prefer Playwright `page.screencast` for intentional demo capture, Playwright traces for audit/debug evidence, and screenshots for milestone proof.
- Treat AI browser control, Browserbase/Stagehand, Vercel agent-browser, and Playwright MCP as optional executors, not proof by themselves.
- Any narration generated with TTS must be disclosed in the run manifest and closeout as synthetic audio.
- Do not clone, imitate, or imply a real person's voice without explicit rights and operator approval.
- Offline mode must not silently degrade into low-quality speech. If final-quality TTS is unavailable, stop at `WAITING_FOR_VOICEOVER_APPROVAL` or `BLOCKED_NO_TTS_PROVIDER`.
- Before closeout, run `git status --short` and verify no generated media is staged or tracked.
- If media appears in git status, block closeout until it is moved to an ignored output directory or explicitly approved as a tiny sanitized fixture.
- Do not claim production-ready recorded-demo proof unless the runtime media lane actually ran and validated nonblank video, non-silent audio, captions/transcripts, and manifest integrity.

## Profile Compatibility

- `solo-fast`: may record only trusted local or demo targets and still must use ephemeral browser state.
- `team-safe`: default shared profile; requires explicit capture approval and must not require `bypassPermissions`.
- `ci-static`: may run only static lint, manifest, fixture, and gitignore checks. It must not launch browsers, access network, call TTS providers, or require secrets.
- `ci-runtime`: may run authenticated recording only with dedicated test credentials, isolated workspace, redacted logs, and no production credentials.

## Input Contract

Before capture, establish:

- Product target: local app command, preview URL, or approved demo URL.
- Audience: buyer, operator, investor, internal team, QA, or owner.
- Objective: what the demo must prove.
- Data policy: allowed fixtures, forbidden real data, and redaction plan.
- Viewports: at minimum the target desktop size; include mobile when the demo is public-facing.
- Languages: default `en` and `es-419`; use `es` only when the target explicitly wants broader Spanish.
- Voice policy: built-in/stock voice by default; custom voice only with consent, eligibility, and operator approval.
- Runtime profile: `solo-fast`, `team-safe`, `ci-static`, or `ci-runtime`.
- Artifact directory: default `.taste/demo-recordings/{run_id}/`.

## Workflow

1. **Taste And Scope Gate**
   - Read `taste.md`, `taste.vision`, `SPEC.md`, and relevant product docs.
   - Classify the demo as product tour, operator workflow, sales demo, QA demo, or owner handoff.
   - Record target audience, allowed data, forbidden data, and risk level.

2. **Deep Research Brief**
   - Use `/deepresearch` discipline for architecture-driving or SOTA demo work.
   - Use official docs for APIs and standards: Playwright, OpenAI TTS, FFmpeg, WebVTT, WCAG, and platform distribution requirements.
   - Keep a source ledger and document conflicts. Example: if provider voice counts differ across docs, record the conflict and require runtime validation.

3. **Evidence Plan**
   - Define exact route(s), fixtures, browser actions, expected end state, viewports, language artifacts, and quality gates.
   - Prefer deterministic Playwright scripts with role/text/test-id locators and web-first assertions.
   - Use AI browser actions only where deterministic automation is impossible or explicitly exploratory.

4. **Storyboard And Script**
   - Generate storyboard only after source routes/data are inspected.
   - Write separate scripts for English and neutral Spanish. Do not create a single mixed-language narration unless the operator explicitly asks.
   - Spanish copy should be calm, professional, neutral Latin American Spanish: `Español neutro latinoamericano, tono sobrio y confiable`.
   - Keep captions authored from the approved script. Transcription may verify or align, but it is not the canonical copy source.

5. **Capture**
   - Use an ephemeral browser context and deterministic fixture data.
   - Prefer Playwright `page.screencast.start({ path, size })` for intentional recording.
   - Capture milestone screenshots and a trace when debug/audit evidence is needed.
   - Close/stop in a safe order: stop screencast, close page/context, then finalize/copy artifacts.

6. **Voiceover And Captions**
   - For final-quality OpenAI TTS, prefer `gpt-4o-mini-tts` with built-in voices, `wav` for assembly, and explicit style instructions per language.
   - Generate narration in short segments per planned cue when possible; measure each segment duration locally and derive WebVTT cue timing from measured durations.
   - Produce `script.en.md`, `script.es.md`, `captions.en.vtt`, and `captions.es.vtt`.
   - Use `en` and `es-419` language metadata unless the operator requests a different BCP 47 tag.
   - Keep WebVTT sidecars as the canonical accessibility artifacts. Burned-in captions may be a secondary export only.

7. **Media Composition**
   - Use FFmpeg with explicit stream mapping for portable renders.
   - Keep sidecar VTTs even when a muxed or burned-caption export exists.
   - Fail closed if FFmpeg, ffprobe, browser capture, or TTS is missing and the requested output requires it.
   - A text-only storyboard is `prompt-only` or `no-media`, not a successful recorded demo.

8. **Distribution Package**
   - Always produce a web-first master package before platform-specific exports.
   - For YouTube, include reviewed caption/subtitle files, title/description drafts per language, thumbnail candidate, and a synthetic/altered-content disclosure recommendation. Do not rely on YouTube auto captions as the quality source of truth.
   - For Apple App Store previews, enforce app-only footage, all-age-safe metadata, fictional account data, no fingers filming the device, 15-30 second exports, maximum 30 fps, stereo audio, and per-language variants when the listing is localized.
   - For Google Play preview videos, prepare YouTube-uploadable public/unlisted embeddable assets, show actual app experience early, keep the first 10-30 seconds understandable when muted, avoid black bars, avoid CTA/ranking/price overlay claims, and localize UI/taglines/audio.
   - For accessible web/social distribution, include same-language captions, translated subtitles when useful, descriptive transcripts, and an audio-description plan or explicit “not needed” justification.

9. **Quality Gates**
   - `route_load_gate`: route loads in required viewport(s); no blank screen or fatal console error.
   - `workflow_truth_gate`: demo states match the real product and allowed fixtures.
   - `operator_comprehension_gate`: each screen exposes state, next action, error/retry path, and completion signal.
   - `interaction_gate`: primary flow is mouse and keyboard operable; focus order preserves meaning.
   - `accessibility_gate`: captions/transcript exist; visual-only information has audio description or text alternative when needed.
   - `media_gate`: video is nonblank, audio is non-silent, caption files are valid enough to parse, and durations are coherent.
   - `safety_gate`: no secrets, no real customer data, no production credentials, no unapproved external publishing.
   - `evidence_gate`: manifest cites commands, scripts, source route(s), screenshots/traces/video/audio/captions, and hashes.

10. **Manifest And Closeout**
   - Emit a sanitized manifest with `artifact_type`, `demo_id`, `run_dir`, `target`, `languages`, `voiceover`, `tts_disclosure`, `artifacts`, `quality_gates`, `retention`, `commands_run`, `risk_flags`, and `verdict`.
   - Record `tts_provider`, `tts_model_or_voice`, `generation_time`, `input_script_path`, and whether the voice is stock, licensed, or custom.
   - Include `created_at`, `expires_at`, `retention_policy`, artifact paths, and `cleanup_command`.
   - Closeout must state whether outputs were retained, pruned, or left for operator review.

## Artifact Manifest Shape

```json
{
  "artifact_type": "demo-recording",
  "demo_id": "YYYYMMDD-HHMMSS-slug",
  "run_dir": ".taste/demo-recordings/YYYYMMDD-HHMMSS-slug",
  "target": {
    "route_or_path": "http://127.0.0.1:3000/demo",
    "audience": "operator",
    "objective": "prove the scheduling workflow"
  },
  "languages": [
    {"code": "en", "script": "script.en.md", "captions": "captions.en.vtt"},
    {"code": "es-419", "script": "script.es.md", "captions": "captions.es.vtt"}
  ],
  "voiceover": {
    "tts_provider": "openai",
    "tts_model_or_voice": "gpt-4o-mini-tts:marin",
    "generation_time": "2026-05-05T00:00:00Z",
    "input_script_path": "script.en.md",
    "voice_kind": "stock"
  },
  "tts_disclosure": {
    "synthetic_audio": true,
    "end_user_disclosure": "Narration is AI-generated."
  },
  "artifacts": {
    "video": "demo.webm",
    "audio": ["voiceover.en.wav", "voiceover.es.wav"],
    "captions": ["captions.en.vtt", "captions.es.vtt"],
    "screenshots": [],
    "trace": ""
  },
  "quality_gates": {
    "route_load": "pass",
    "workflow_truth": "pass",
    "operator_comprehension": "pass",
    "accessibility": "pass",
    "media": "pass",
    "safety": "pass"
  },
  "retention": {
    "created_at": "2026-05-05T00:00:00Z",
    "expires_at": "2026-05-12T00:00:00Z",
    "retention_policy": "default-7-days",
    "cleanup_command": "rm -rf .taste/demo-recordings/YYYYMMDD-HHMMSS-slug"
  },
  "commands_run": [],
  "risk_flags": [],
  "verdict": "pass"
}
```

## Static Verification

For contract and release checks:

```bash
bash scripts/demo-smoke.sh --fixtures
bash scripts/harness-capability-map.sh --check --json
bash scripts/harness-eval.sh --json
env HARNESS_STATIC_CI=1 bash scripts/test-harness.sh
bash scripts/release-check.sh --static-only
git diff --check
```

## Runtime Verification

For actual recorded media proof, use the runtime lane:

```bash
bash scripts/demo-smoke.sh --runtime .taste/demo-recordings/{run_id}/manifest.json
```

Runtime PASS requires:

- manifest is valid and sanitized
- generated media is ignored by git
- video exists and is nonblank
- audio exists and is non-silent
- English and Spanish scripts/captions exist
- TTS disclosure exists when voiceover is synthetic
- no obvious credential pattern appears in manifest, scripts, captions, or transcript text

## Blockers

Return `BLOCKED` when:

- target needs production credentials or real customer data
- capture would use a personal browser profile
- requested output requires TTS/browser/FFmpeg and the dependency is unavailable
- generated media is not ignored by git
- captions, transcript, AI voice disclosure, or retention metadata are missing
- verification only proves static docs but the user asked for actual recorded media
