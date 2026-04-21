#!/bin/bash
# minmaxing memory CLI — 5-tier memory system
# Usage: memory add <tier> <content> [--tags TAG1,TAG2]
#        memory list [--tier TIERS]
#        memory search <query>
#        memory stats
#        memory recall <task> [--depth simple|medium|complex]
#        memory causal-factors [--outcome success|failure] [--limit N]

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

# Python call helper — runs memory Python package for SQLite FTS5 search
# Falls back gracefully if Python fails
python_call() {
  python3 -m memory.cli "$@" 2>/dev/null || true
}

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
        # Append to session log (episodic is session-only, no Python sync)
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
        # Dual-write to SQLite (best-effort, warn on failure)
        python3 -m memory.cli add semantic "$content" --tags "${tags:-untagged}" 2>/dev/null || echo "  [WARN] SQLite sync failed for semantic"
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
        # Dual-write to SQLite (best-effort, warn on failure)
        python3 -m memory.cli add procedural "$content" --tags "${tags:-untagged}" 2>/dev/null || echo "  [WARN] SQLite sync failed for procedural"
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
        # Dual-write to SQLite (best-effort, warn on failure)
        python3 -m memory.cli add error-solution "$error" "$solution" 2>/dev/null || echo "  [WARN] SQLite sync failed for error-solution"
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
        # Dual-write to SQLite (best-effort, warn on failure)
        python3 -m memory.cli add graph "$content" --tags "${tags:-untagged}" 2>/dev/null || echo "  [WARN] SQLite sync failed for graph"
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
    # Delegate to Python FTS5 search if available, fall back to grep
    echo "=== Searching for: $query ==="
    if python_call search "$query" 2>/dev/null; then
      # Python search succeeded
      :
    else
      # Fallback to grep
      grep -r --include="*.md" "$query" "${MEMORY_DIR}/" 2>/dev/null | head -20
      grep -r "$query" "${TASTE_DIR}/sessions/"*.jsonl 2>/dev/null | head -10
    fi
    ;;

  stats)
    echo "=== Memory Stats ==="
    echo ""
    echo "--- Flat Files ---"
    echo "Episodic (sessions today):"
    [ -f "$SESSION_FILE" ] && wc -l < "$SESSION_FILE" || echo "  0 entries"
    echo ""
    echo "Decisions: $(ls "${MEMORY_DIR}/Decisions/" 2>/dev/null | wc -l) notes"
    echo "Patterns: $(ls "${MEMORY_DIR}/Patterns/" 2>/dev/null | wc -l) notes"
    echo "Errors: $(ls "${MEMORY_DIR}/Errors/" 2>/dev/null | wc -l) notes"
    echo "Stories: $(ls "${MEMORY_DIR}/Stories/" 2>/dev/null | wc -l) notes"

    # SQLite counts (best-effort)
    echo ""
    echo "--- SQLite (FTS5) ---"
    if ! python_call stats 2>/dev/null; then
      echo "SQLite not available (python memory.cli not installed)"
    fi
    ;;

  recall)
    task="${1:-}"
    if [ -z "$task" ]; then
      echo "Usage: memory recall <task_description> [--depth simple|medium|complex]"
      exit 1
    fi
    depth="${2:-medium}"
    # Strip --depth if passed as flag
    if [ "$depth" = "--depth" ]; then
      depth="${3:-medium}"
    fi
    python_call recall "$task" --depth "$depth" || echo "Recall failed: python memory.cli not available"
    ;;

  causal-factors)
    outcome="${1:-success}"
    limit="${2:-5}"
    # Handle --outcome and --limit flags
    if [ "$outcome" = "--outcome" ]; then
      outcome="${2:-success}"
      limit="${4:-5}"
    fi
    if [ "$outcome" != "success" ] && [ "$outcome" != "failure" ]; then
      limit="${outcome}"
      outcome="success"
    fi
    python_call causal-factors --outcome "$outcome" --limit "$limit" || echo "Causal-factors failed: python memory.cli not available"
    ;;

  *)
    echo "minmaxing memory CLI"
    echo ""
    echo "Usage: memory <command> [args]"
    echo ""
    echo "Commands:"
    echo "  add <tier> <content> [--tags TAG1,TAG2]  Add memory"
    echo "  list [--tier TIERS]                      List memories"
    echo "  search <query>                           Search memories (FTS5)"
    echo "  stats                                    Show stats (flat + SQLite)"
    echo "  recall <task> [--depth simple|medium|complex]  Recall task context"
    echo "  causal-factors [--outcome success|failure] [--limit N]  Analyze causal factors"
    echo ""
    echo "Tiers: episodic, semantic, procedural, error-solution, graph"
    ;;
esac
