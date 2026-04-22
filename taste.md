---
taste: spec
version: "2.0"
created: 2026-04-20
frontend:
  colors:
    canvas: "#F7F5F2"
    surface: "#FFFFFF"
    ink: "#1A1C1E"
    muted: "#6C7278"
    accent: "#B8422E"
    success: "#1F6F4A"
    warning: "#A66200"
    danger: "#B42318"
  typography:
    display:
      fontFamily: Public Sans
      fontSize: 3rem
      fontWeight: 700
      lineHeight: 1.1
      letterSpacing: -0.03em
    heading:
      fontFamily: Public Sans
      fontSize: 2rem
      fontWeight: 600
      lineHeight: 1.2
      letterSpacing: -0.02em
    body:
      fontFamily: Public Sans
      fontSize: 1rem
      fontWeight: 400
      lineHeight: 1.6
    label:
      fontFamily: Space Grotesk
      fontSize: 0.75rem
      fontWeight: 600
      lineHeight: 1
      letterSpacing: 0.08em
  spacing:
    xs: 4px
    sm: 8px
    md: 16px
    lg: 24px
    xl: 32px
    section: 48px
  rounded:
    sm: 4px
    md: 8px
    lg: 12px
    xl: 20px
    full: 9999px
  components:
    button-primary:
      backgroundColor: "{frontend.colors.accent}"
      textColor: "{frontend.colors.surface}"
      typography: "{frontend.typography.label}"
      rounded: "{frontend.rounded.md}"
      height: 44px
      padding: 0 16px
    button-secondary:
      backgroundColor: "{frontend.colors.surface}"
      textColor: "{frontend.colors.ink}"
      typography: "{frontend.typography.label}"
      rounded: "{frontend.rounded.md}"
      height: 44px
      padding: 0 16px
    input-field:
      backgroundColor: "{frontend.colors.surface}"
      textColor: "{frontend.colors.ink}"
      typography: "{frontend.typography.body}"
      rounded: "{frontend.rounded.md}"
      height: 44px
      padding: 0 12px
    surface-card:
      backgroundColor: "{frontend.colors.surface}"
      textColor: "{frontend.colors.ink}"
      rounded: "{frontend.rounded.lg}"
      padding: "{frontend.spacing.lg}"
    list-item-interactive:
      backgroundColor: "{frontend.colors.surface}"
      textColor: "{frontend.colors.ink}"
      rounded: "{frontend.rounded.md}"
      padding: "{frontend.spacing.md}"
    status-badge:
      backgroundColor: "{frontend.colors.canvas}"
      textColor: "{frontend.colors.muted}"
      typography: "{frontend.typography.label}"
      rounded: "{frontend.rounded.full}"
      padding: 4px 10px
backend:
  contractStyle: contract-first
  errorModel: structured-and-stable
  observability: logs-metrics-traces-with-correlation-id
  security: least-privilege-and-explicit-boundaries
  rollback: reversible-and-evidence-backed
---

# Taste Spec

Define what is acceptable in this project. AI agents consult this before accepting output.

## Overview

This kernel defines a correctness-first product system for both interface work and system behavior. Frontends should feel clear, calm, and intentional rather than flashy, while backends should feel explicit, inspectable, and safe to evolve.

The goal is not to impose one brand aesthetic on every project. The goal is to give agents a reusable structure for making coherent frontend decisions and equally coherent backend decisions without drifting into novelty, hidden coupling, or "good enough" shortcuts.

## Design Principles

- SPEC-first: write spec before code.
- Research-first: verify external claims with current sources before committing to a plan.
- Separate verifier from implementer: the PEV loop is mandatory for file-changing work.
- Correctness over speed: throughput matters only after the task is well understood.
- Reusable systems over one-off flourishes: design and architecture should compound across tasks.
- Contract-first backend thinking: behavior, failure modes, and rollback paths should be explicit before implementation.
- Accessible by default: clarity, contrast, keyboard reachability, and readable copy are not optional polish.

## Frontend System

### Colors

Use a restrained, editorial palette. Most surfaces should be quiet neutrals so the accent color carries the visual intent instead of the whole interface shouting at once.

- `canvas` is the page foundation. Prefer warm off-white or soft neutral backgrounds over pure white.
- `surface` is for cards, inputs, tables, and raised containers.
- `ink` is the default text and high-emphasis border color.
- `muted` is for metadata, helper copy, dividers, and low-emphasis controls.
- `accent` is the primary action color. Use it deliberately, not everywhere.
- `success`, `warning`, and `danger` are semantic states only. Never use them as decorative brand color.

### Typography

Typography should feel structured and confident, not generic.

- Public Sans is the default narrative voice for display, headings, and body copy.
- Space Grotesk is reserved for labels, metadata, badges, counters, and system-like UI fragments.
- Display and heading styles should create hierarchy through size and weight, not through random color changes.
- Body text should optimize for long reading and predictable rhythm.
- Labels should be compact, legible, and slightly tracked for scanability.

### Layout & Spacing

Use a disciplined spacing rhythm.

- The base spacing system is 4px / 8px aligned.
- Prefer generous grouping and containment over overly dense control clusters.
- Default container padding should feel deliberate and breathable.
- Use one clear primary column or grid before introducing nested layout complexity.
- Keep interactive areas comfortably targetable on both desktop and mobile.

### Elevation & Shapes

Hierarchy should come from containment, contrast, and spacing before heavy effects.

- Use soft radii by default: small for controls, medium for inputs, larger for cards and modal surfaces.
- Prefer borders and tonal contrast over deep shadow stacks.
- If depth is needed, it should clarify hierarchy, not create visual noise.
- Rounded full-pill treatments are for badges, chips, and compact status elements only.

### Components

Agents should treat these as the default reusable primitives:

- `button-primary`: one clear call to action, accent-backed, high-contrast label.
- `button-secondary`: neutral surface action, lower emphasis than primary.
- `input-field`: calm, readable form control with obvious focus state and enough padding to scan comfortably.
- `surface-card`: grouped content container for specs, summaries, settings, or workflow output.
- `list-item-interactive`: interactive row pattern for menus, search results, run history, or audit findings.
- `status-badge`: compact semantic state label for workflow status, severity, or environment markers.

Variants are acceptable, but they should feel like descendants of these components rather than brand-new inventions every time.

### Interaction & Accessibility

Accessibility is a hard requirement, not a best-effort aspiration.

- Meet WCAG AA contrast for normal text and controls.
- Visible focus states are mandatory for every interactive element.
- Support keyboard-first navigation for all major actions and flows.
- Never rely on color alone to communicate status, severity, or required action.
- Use explicit loading, empty, success, and error states instead of silent transitions.
- Copy should be concise, specific, and calm under stress.

## Backend System

### API & Contract Design

Backend changes should start from the consumer contract, not from internal convenience.

- Prefer stable, explicit request and response shapes.
- Break behavior intentionally, never accidentally.
- Additive changes are preferred over silently changing meaning.
- Use consistent naming, predictable resource boundaries, and obvious action semantics.
- If an operation is important enough to expose, it is important enough to document and verify.

### Data Boundaries & State

Make state ownership obvious.

- One subsystem should own one source of truth.
- Avoid hidden bidirectional coupling between UI state, transport state, and persistence state.
- Validation should happen at the boundary, not only deep inside the implementation.
- Migrations, derived data, and background jobs should preserve recoverability and traceability.

### Errors, Resilience & Idempotency

Failure should be modeled, not hand-waved.

- Prefer structured errors with stable machine-readable codes and concise human-readable summaries.
- Mutating operations should consider idempotency and retry safety where duplication is possible.
- Timeouts, fallback behavior, and partial-failure handling should be explicit in the plan.
- Do not leak internal implementation details or secrets through error messages.

### Observability & Operations

If a system matters, it must be debuggable in production-like conditions.

- Emit structured logs for meaningful state transitions and failure events.
- Preserve correlation or request identifiers across boundaries when possible.
- Prefer metrics and traces for recurring operational questions, not ad hoc detective work.
- Destructive or high-risk operations should leave an audit trail.
- Rollback steps should be concrete enough to execute under pressure.

### Security & Privacy

Security is a product constraint, not a cleanup task.

- Assume all external input is untrusted until validated.
- Prefer explicit authentication and authorization checks over ambient trust.
- Apply least-privilege defaults for credentials, services, and operators.
- Never log secrets, tokens, raw credentials, or sensitive personal data casually.
- Collect and retain only the data required to deliver the feature or audit the action.

## Code Style

- Small functions, single responsibility, clear call sites.
- Explicit over implicit, especially around side effects and state mutation.
- Prefer names that reveal intent over abbreviations that save keystrokes.
- Keep formatting boring and readable.
- Comments should explain why a choice exists, not restate the code mechanically.
- Avoid premature optimization, but do not ignore obvious complexity cliffs.

## Architecture

- Supervisor/worker patterns are acceptable when ownership is clear and verification is explicit.
- File isolation between parallel agents is preferred whenever work can be decomposed safely.
- Thin orchestration layers, explicit domain boundaries, and clear integration seams beat magical shared state.
- Quality gates belong before progression, not after damage.
- Design the rollback path while the change is still cheap to reason about.

## Naming Conventions

- Prefer semantic token names over aesthetic nicknames in machine-readable config.
- Use consistent nouns for resources and clear verbs for actions or jobs.
- UI component names should describe purpose, not implementation detail.
- Status, severity, and workflow states should be named consistently across UI, logs, and APIs.
- Avoid ambiguous suffixes like `new`, `final`, `temp`, or `misc`.

## Do's and Don'ts

### Do's

- Do preserve a small set of reusable UI primitives and extend them consistently.
- Do write backend behavior from a stable contract outward.
- Do make success, failure, loading, and rollback states explicit.
- Do keep the system inspectable through logs, metrics, traces, and readable specs.

### Don'ts

- Don't invent a new visual language for every screen or feature.
- Don't couple product behavior to incidental transport quirks or fragile UI state.
- Don't hide failure behind silent retries or vague messages.
- Don't trade recoverability and clarity for short-term implementation speed.
