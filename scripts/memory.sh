#!/bin/bash
# minmaxing memory CLI — 5-tier memory system
# Usage: memory add <tier> <content> [--tags TAG1,TAG2]
#        memory list [--tier TIERS]
#        memory search <query>
#        memory stats

set -e

MEMORY_DIR="${MEMORY_DIR:-$(pwd)/obsidian/Memory}"
TASTE_DIR="${TASTE_DIR:-$(pwd)/.taste}"
DATE=$(date +%Y-%m-%d)
DATE_TIME=$(date +%Y-%m-%dT%H:%M:%S)
SESSION_FILE="${TASTE_DIR}/sessions/${DATE}.jsonl"

# Ensure directories exist
mkdir -p "${TASTE_DIR}/sessions"
mkdir -p "${MEMORY_DIR}/Decisions"
mkdir -p "${MEMORY_DIR}/Patterns"
mkdir -p "${MEMORY_DIR}/Errors"
mkdir -p "${MEMORY_DIR}/Stories"

# Parse arguments
CMD="${1:-}"
shift || true

case "$CMD" in
  add)
    tier="${1:-}"
    content="${2:-}"
    tags=""
    while [ $# -ge 1 ]; do
      case "$1" in
        --tags) tags="$2"; shift 2 ;;
        *) shift ;;
      esac
    done

    if [ -z "$tier" ] || [ -z "$content" ]; then
      echo "Usage: memory add <tier> <content> [--tags TAG1,TAG2]"
      echo "Tiers: episodic, semantic, procedural, error-solution, graph"
      exit 1
    fi

    case "$tier" in
      episodic)
        # Append to session log
        mkdir -p "${TASTE_DIR}/sessions"
        echo "{\"timestamp\":\"${DATE_TIME}\",\"type\":\"episodic\",\"content\":\"$(echo "$content" | sed 's/"/\\"/g')\"}" >> "$SESSION_FILE"
        echo "Added episodic: $content"
        ;;
      semantic)
        file="${MEMORY_DIR}/Decisions/$(date +%s).md"
        cat > "$file" <<EOF
---
type: semantic
date: ${DATE}
tags: [${tags:-untagged}]
---

$(echo "$content" | sed 's/"/\\"/g')
EOF
        echo "Added semantic: $content → $file"
        ;;
      procedural)
        file="${MEMORY_DIR}/Patterns/$(date +%s).md"
        cat > "$file" <<EOF
---
type: procedural
date: ${DATE}
tags: [${tags:-untagged}]
---

$(echo "$content" | sed 's/"/\\"/g')
EOF
        echo "Added procedural: $content → $file"
        ;;
      error-solution)
        # content format: "error" "solution"
        error=$(echo "$content" | cut -d'"' -f2)
        solution=$(echo "$content" | cut -d'"' -f4)
        file="${MEMORY_DIR}/Errors/$(date +%s).md"
        cat > "$file" <<EOF
---
type: error-solution
date: ${DATE}
error: "$(echo "$error" | sed 's/"/\\"/g')"
---

## Error
$(echo "$error" | sed 's/"/\\"/g')

## Solution
$(echo "$solution" | sed 's/"/\\"/g')
EOF
        echo "Added error-solution pair → $file"
        ;;
      graph)
        file="${MEMORY_DIR}/Stories/$(date +%s).md"
        cat > "$file" <<EOF
---
type: graph
date: ${DATE}
tags: [${tags:-untagged}]
---

$(echo "$content" | sed 's/"/\\"/g')
EOF
        echo "Added graph: $content → $file"
        ;;
      *)
        echo "Unknown tier: $tier"
        echo "Tiers: episodic, semantic, procedural, error-solution, graph"
        exit 1
        ;;
    esac
    ;;

  list)
    tier="${1:-}"
    limit="${2:-20}"
    case "$tier" in
      episodic)
        [ -f "$SESSION_FILE" ] && tail -n "$limit" "$SESSION_FILE" || echo "No episodic records today"
        ;;
      semantic|procedural|error-solution|graph)
        folder="${tier//-/_}"
        [ "$tier" = "error-solution" ] && folder="Errors"
        [ "$tier" = "procedural" ] && folder="Patterns"
        [ "$tier" = "semantic" ] && folder="Decisions"
        [ "$tier" = "graph" ] && folder="Stories"
        echo "=== $tier ==="
        ls "${MEMORY_DIR}/${folder}/" 2>/dev/null | head -n "$limit" || echo "No records"
        ;;
      "")
        echo "=== Episodic (today) ==="
        [ -f "$SESSION_FILE" ] && tail -n 5 "$SESSION_FILE" || echo "(empty)"
        echo ""
        echo "=== Decisions ==="
        ls "${MEMORY_DIR}/Decisions/" 2>/dev/null | head -5 || echo "(empty)"
        echo "=== Patterns ==="
        ls "${MEMORY_DIR}/Patterns/" 2>/dev/null | head -5 || echo "(empty)"
        echo "=== Errors ==="
        ls "${MEMORY_DIR}/Errors/" 2>/dev/null | head -5 || echo "(empty)"
        ;;
      *)
        echo "Unknown tier: $tier"
        ;;
    esac
    ;;

  search)
    query="${1:-}"
    if [ -z "$query" ]; then
      echo "Usage: memory search <query>"
      exit 1
    fi
    echo "=== Searching for: $query ==="
    grep -r --include="*.md" "$query" "${MEMORY_DIR}/" 2>/dev/null | head -20
    grep -r "$query" "${TASTE_DIR}/sessions/"*.jsonl 2>/dev/null | head -10
    ;;

  stats)
    echo "=== Memory Stats ==="
    echo ""
    echo "Episodic (sessions today):"
    [ -f "$SESSION_FILE" ] && wc -l < "$SESSION_FILE" || echo "  0 entries"
    echo ""
    echo "Decisions: $(ls "${MEMORY_DIR}/Decisions/" 2>/dev/null | wc -l) notes"
    echo "Patterns: $(ls "${MEMORY_DIR}/Patterns/" 2>/dev/null | wc -l) notes"
    echo "Errors: $(ls "${MEMORY_DIR}/Errors/" 2>/dev/null | wc -l) notes"
    echo "Stories: $(ls "${MEMORY_DIR}/Stories/" 2>/dev/null | wc -l) notes"
    ;;

  *)
    echo "minmaxing memory CLI"
    echo ""
    echo "Usage: memory <command> [args]"
    echo ""
    echo "Commands:"
    echo "  add <tier> <content> [--tags TAG1,TAG2]  Add memory"
    echo "  list [--tier TIERS]                      List memories"
    echo "  search <query>                           Search memories"
    echo "  stats                                    Show stats"
    echo ""
    echo "Tiers: episodic, semantic, procedural, error-solution, graph"
    ;;
esac
