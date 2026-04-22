# /tastebootstrap

Explicit first-run kernel bootstrap for fresh repos. Use this before `/workflow` when `taste.md` and `taste.vision` do not exist yet.

**Use when:** User says "new repo", "fresh folder", "bootstrap taste", "define taste", or when onboarding a project that has not answered the kernel interview yet.

**Compatibility note:** This is the dedicated entrypoint for the same bootstrap contract documented under `/align --bootstrap`, but it is easier to discover during setup and first-run onboarding.

---

## Purpose

Collect the full 10-question kernel interview, then write `taste.md` and `taste.vision` to project root so every later `/workflow`, `/audit`, and `/autoplan` run has an explicit operating kernel to follow.

Do not skip this interview for a fresh repo.

---

## Execution Protocol

### Step 1: Check Current State

1. Check whether `taste.md` and `taste.vision` already exist.
2. If both already exist:
   - read them first
   - do not overwrite them silently
   - explain that `/tastebootstrap` is mainly for fresh repos and suggest `/align` if the user only wants to refine or challenge existing taste
3. If either file is missing, continue with the bootstrap interview.

### Step 2: Run the Bootstrap Interview

Ask the 10 questions directly.

- Ask them one at a time and wait for each answer before proceeding.
- If the user already supplied one or more answers up front, reuse that information and only ask the unanswered questions.
- Do not collapse the interview into fewer than 10 questions unless the user has already fully answered the missing parts.
- Keep the questions concrete and repo-defining, not generic startup advice.

### Bootstrap Interview (10 questions)

1. Design Principles — "What are the non-negotiable design principles?"
2. Project Intent — "Why does this project exist, who is it for, and what should it be great at?"
3. Experience Direction — "What kind of experience should this project create, and what should it avoid?"
4. Communication & Interaction — "How should UI, CLI, docs, workflows, or other touchpoints communicate and behave?"
5. Accessibility & Inclusion — "What accessibility, inclusion, and clarity rules are non-negotiable?"
6. Interfaces & Contracts — "What public interfaces or contracts must stay explicit and stable?"
7. Data & Ownership — "What data, state, and ownership boundaries should agents preserve?"
8. Operations & Safety — "What error-handling, observability, rollback, and security rules are required?"
9. Code & Architecture — "What code style, architecture, and naming rules are preferred?"
10. Success & Non-Goals — "What does success look like, what is out of scope, and which tradeoffs are acceptable?"

### Step 3: Write the Taste Files

When the 10 answers are complete, write `taste.md` and `taste.vision` to project root using the following structure.

#### `taste.md`

- YAML front matter must include:
  - `taste`
  - `version`
  - `created`
  - `principles`
  - `experience.posture`
  - `experience.accessibility`
  - `interfaces.contractStyle`
  - `interfaces.stateBoundaries`
  - `system.errorModel`
  - `system.observability`
  - `system.security`
  - `system.rollback`
  - `delivery.verification`
- Body section order must be:
  1. `## Overview`
  2. `## Design Principles`
  3. `## Experience & Interaction`
  4. `## Interfaces & Contracts`
  5. `## System Behavior`
  6. `## Code Style`
  7. `## Architecture`
  8. `## Naming Conventions`
  9. `## Do's and Don'ts`
- `## Experience & Interaction` must contain:
  - `### Voice & UX`
  - `### Interaction Patterns`
  - `### Accessibility & Inclusion`
- `## Interfaces & Contracts` must contain:
  - `### Public Surfaces`
  - `### Data & State Boundaries`
- `## System Behavior` must contain:
  - `### Errors & Resilience`
  - `### Observability & Operations`
  - `### Security & Privacy`

#### `taste.vision`

- YAML front matter must include:
  - `taste`
  - `version`
  - `created`
- Body section order must be:
  1. `## Intent`
  2. `## Audience`
  3. `## Success Criteria`
  4. `## Non-Goals`
  5. `## Values & Tradeoffs`
  6. `## Experience Promise`

### Step 4: Map Answers Cleanly

- Questions 1 and 3-9 primarily shape `taste.md`.
- Questions 2 and 10 primarily shape `taste.vision`, but should sharpen `taste.md` where needed.
- Keep the kernel broad enough to work for products, APIs, CLIs, agents, automation, or mixed systems.
- Only add frontend- or backend-specific rules when they genuinely matter for the project.

### Output

- Writes `taste.md` and `taste.vision` to project root
- Confirms that the repo is now ready for `/workflow`
- Output: `TASTE_DEFINED`

---

## Quality Gates

- All 10 bootstrap questions must be answered in fresh-repo mode.
- Both `taste.md` and `taste.vision` must be written.
- The required front matter keys and section headings must exist.
- Do not proceed to implementation planning before taste is defined.

---

## Anti-Patterns

- Skipping straight to `/workflow` in a fresh repo without defining taste first
- Writing only one of the two taste files
- Using a generic template without incorporating the user's answers
- Overwriting existing taste files without explicit user intent
