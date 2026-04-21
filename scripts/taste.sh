#!/bin/bash
# minmaxing taste system CLI
# Manages taste.md, taste.vision, and taste.memory (JSONL log)
# Usage: taste.sh init|log|review|digest

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
created: PLACEHOLDER_DATE
---

# Taste Spec

Define what is acceptable in this project. AI agents consult this before accepting output.

## Design Principles

<!-- Add your principles here -->

## Aesthetic Rules

<!-- Color, typography, spacing rules -->

## Code Style

<!-- Naming, structure, patterns -->

## Architecture

<!-- Component boundaries, data flow -->

## Naming Conventions

<!-- File, function, variable naming -->
EOF
      echo "Created taste.md"
    fi

    if [ -f "$TASTE_VISION" ]; then
      echo "taste.vision already exists. Skipping."
    else
      cat > "$TASTE_VISION" <<'EOF'
---
taste: vision
created: PLACEHOLDER_DATE
---

# Vision

Why does this project exist? What problem does it solve? What does success look like?

## Intent

<!-- The "why" behind this project -->

## Success Criteria

<!-- What does "done" look like? -->

## Non-Goals

<!-- What this project explicitly does NOT do -->

## Taste

<!-- What makes this project feel cohesive and well-crafted? -->
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
    ;;
esac
