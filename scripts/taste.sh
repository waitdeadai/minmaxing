#!/bin/bash
# minmaxing taste system CLI
# Manages taste.md, taste.vision, and taste.memory (JSONL log)
# Usage: taste.sh init|log|review|digest|score

set -e

TASTE_DIR="${TASTE_DIR:-$(pwd)/.taste}"
TASTE_MEMORY="${TASTE_DIR}/taste.memory"
TASTE_MD="$(pwd)/taste.md"
TASTE_VISION="$(pwd)/taste.vision"
DATE=$(date +%Y-%m-%dT%H:%M:%S)

mkdir -p "${TASTE_DIR}"

CMD="${1:-}"
shift || true

case "$CMD" in
  init)
    if [ -f "$TASTE_MD" ]; then
      echo "taste.md already exists. Skipping."
    else
      cat > "$TASTE_MD" <<'EOF'
---
taste: spec
version: "2.0"
created: PLACEHOLDER_DATE
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

Describe the overall system feel.

- What should the frontend feel like?
- What should the backend optimize for?
- What should never happen by accident?

## Design Principles

- <!-- Non-negotiable rules such as SPEC-first, research-first, or correctness over speed -->

## Frontend System

### Colors

- <!-- How should color be used semantically? -->

### Typography

- <!-- Which fonts, hierarchy, and label treatments are acceptable? -->

### Layout & Spacing

- <!-- What spacing rhythm, density, and layout model should agents preserve? -->

### Elevation & Shapes

- <!-- How should depth, borders, radius, and containment work? -->

### Components

- <!-- How should the default primitives behave and when should variants appear? -->

### Interaction & Accessibility

- <!-- Contrast, focus states, keyboard rules, loading and error states -->

## Backend System

### API & Contract Design

- <!-- What request/response and versioning style should backend work follow? -->

### Data Boundaries & State

- <!-- What owns state and where should validation happen? -->

### Errors, Resilience & Idempotency

- <!-- How should failure be modeled and what retry/rollback rules apply? -->

### Observability & Operations

- <!-- What logs, metrics, traces, and audit trails are expected? -->

### Security & Privacy

- <!-- What auth, secret handling, privacy, and least-privilege rules apply? -->

## Code Style

- <!-- Naming, structure, abstraction, and commenting preferences -->

## Architecture

- <!-- Component boundaries, data flow, orchestration, and rollback rules -->

## Naming Conventions

- <!-- File, function, component, API, and state naming conventions -->

## Do's and Don'ts

### Do's

- <!-- Short, explicit guardrails agents can apply directly -->

### Don'ts

- <!-- Things agents should avoid even if they seem faster -->
EOF
      echo "Created taste.md"
    fi

    if [ -f "$TASTE_VISION" ]; then
      echo "taste.vision already exists. Skipping."
    else
      cat > "$TASTE_VISION" <<'EOF'
---
taste: vision
version: "2.0"
created: PLACEHOLDER_DATE
---

# Vision

Why does this project exist? What kind of experience and system behavior should it produce?

## Intent

- <!-- The "why" behind this project -->

## Audience

- <!-- Who is this for and what context are they in? -->

## Success Criteria

- <!-- Frontend, backend, and workflow success conditions -->

## Non-Goals

- <!-- What this project explicitly does NOT do -->

## Values & Tradeoffs

- <!-- What do we optimize for when trade-offs are unavoidable? -->

## Experience Promise

- <!-- How should the product feel to use and how should the system feel to operate? -->
EOF
      echo "Created taste.vision"
    fi

    echo ""
    echo "Taste system initialized."
    echo "  taste.md: $([ -f "$TASTE_MD" ] && echo 'exists' || echo 'missing')"
    echo "  taste.vision: $([ -f "$TASTE_VISION" ] && echo 'exists' || echo 'missing')"
    ;;

  log)
    verdict="${1:-}"
    task="${2:-}"
    reasoning="${3:-}"
    severity="${4:-P2}"

    if [ -z "$verdict" ]; then
      echo "Usage: taste.sh log <VERDICT> <task> [reasoning] [severity]"
      echo "VERDICT: APPROVE | REVISE | REJECT"
      echo "severity: P0 | P1 | P2 | P3 (default P2)"
      exit 1
    fi

    entry=$(cat <<EOF
{"timestamp":"${DATE}","verdict":"${verdict}","task":"$(echo "$task" | sed 's/"/\\"/g')","reasoning":"$(echo "$reasoning" | sed 's/"/\\"/g')","severity":"${severity}"}
EOF
)

    echo "$entry" >> "$TASTE_MEMORY"
    echo "Logged: [$severity] ${verdict} — ${task}"
    ;;

  review)
    echo "=== Recent Taste Memory ==="
    [ -f "$TASTE_MEMORY" ] && tail -20 "$TASTE_MEMORY" || echo "(empty)"
    echo ""
    echo "=== taste.md exists ==="
    [ -f "$TASTE_MD" ] && echo "yes ($(wc -l < "$TASTE_MD") lines)" || echo "no"
    echo "=== taste.vision exists ==="
    [ -f "$TASTE_VISION" ] && echo "yes ($(wc -l < "$TASTE_VISION") lines)" || echo "no"
    ;;

  digest)
    if ! command -v claude &> /dev/null; then
      echo "claude not found. Install Claude Code first."
      exit 1
    fi
    echo "Digesting taste.memory into taste.md principles..."
    echo ""
    echo "(This would use AI to extract principles from taste.memory entries)"
    echo "For now, manually review taste.memory and update taste.md"
    echo ""
    echo "Recent entries:"
    tail -10 "$TASTE_MEMORY" 2>/dev/null || echo "(empty)"
    ;;

  score)
    if ! command -v claude &> /dev/null; then
      echo "claude not found. Install Claude Code first."
      exit 1
    fi

    if [ ! -f "$TASTE_MD" ] || [ ! -f "$TASTE_VISION" ]; then
      echo "taste.md and taste.vision must exist. Run 'taste.sh init' first."
      exit 1
    fi

    # Collect remaining args as task description
    task_desc="$*"

    if [ -z "$task_desc" ]; then
      echo "Usage: taste.sh score \"<task description>\""
      echo ""
      echo "Scores task alignment against taste.md and taste.vision (0-10)"
      exit 1
    fi

    echo "Scoring alignment..."

    # Build prompt with task embedded
    # Note: claude will read taste.md and taste.vision relative to cwd
    prompt="Read $(pwd)/taste.md and $(pwd)/taste.vision, then score this task for alignment with them.

Return ONLY a single line in this exact format:
SCORE: <number 0-10> | <one sentence explanation>

Be strict. 0 = completely against taste, 10 = perfect alignment.

TASK: $task_desc"

    result=$(claude --print "$prompt" 2>/dev/null)

    echo "$result"
    ;;

  *)
    echo "minmaxing taste CLI"
    echo ""
    echo "Usage: taste.sh <command>"
    echo ""
    echo "Commands:"
    echo "  init     Initialize taste.md and taste.vision"
    echo "  log      Log a verdict to taste.memory"
    echo "  review   Show recent taste.memory entries"
    echo "  digest   Extract principles from taste.memory → taste.md"
    echo "  score    Score task alignment against taste (0-10)"
    ;;
esac
