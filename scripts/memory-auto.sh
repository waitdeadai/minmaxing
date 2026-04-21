#!/bin/bash
# minmaxing memory auto — session start/end hooks
# Called by start-session.sh

TASTE_DIR="${TASTE_DIR:-$(pwd)/.taste}"
SESSION_FILE="${TASTE_DIR}/sessions/$(date +%Y-%m-%d).jsonl"
DATE_TIME=$(date +%Y-%m-%dT%H:%M:%S)

episodic_start() {
    mkdir -p "${TASTE_DIR}/sessions"
    echo "{\"timestamp\":\"${DATE_TIME}\",\"type\":\"session_start\",\"model\":\"MiniMax-M2.7-highspeed\",\"agents\":\"${MAX_PARALLEL_AGENTS:-10}\"}" >> "$SESSION_FILE"
    echo "[Memory] Session started at ${DATE_TIME}"

    # Session counter — tracks total sessions for periodic taste review
    SESSION_COUNT_FILE="${TASTE_DIR}/session_count"
    mkdir -p "${TASTE_DIR}"
    COUNT=$(cat "$SESSION_COUNT_FILE" 2>/dev/null || echo 0)
    NEXT=$((COUNT + 1))
    echo "$NEXT" > "$SESSION_COUNT_FILE"
    echo "[Memory] Session #${NEXT}"

    # Check if periodic taste review is due (every 30 sessions)
    if [ $((NEXT % 30)) -eq 0 ]; then
        echo "[Memory] Taste review due — run /align --review"
    fi

    # Check causal graph for high failure factors (>70% correlation)
    python3 -c "
import sys
sys.path.insert(0, '$(pwd)')
try:
    from memory.causal import get_failure_factors
    factors = get_failure_factors(limit=3)
    for f in factors:
        if f['weight'] < 0.3:
            print(f'[Memory] WARNING: Causal factor \"{f[\"factor\"]}\" has {int((1-f[\"weight\"])*100)}% failure correlation — consider /align --review')
            break
except Exception as e:
    pass
" 2>/dev/null || true

    # Trigger auto-capture: increment episode count and check consolidation
    python3 -c "
import sys
sys.path.insert(0, '$(pwd)')
try:
    from memory.consolidation import increment_episode_count, maybe_consolidate
    count = increment_episode_count()
    print(f'[Memory] Episode count since last consolidation: {count}')
    result = maybe_consolidate()
    if result.get('triggered'):
        print(f'[Memory] Consolidation triggered: {result}')
except Exception as e:
    print(f'[Memory] Auto-capture skipped: {e}')
" 2>/dev/null || echo "[Memory] Auto-capture: python not available"
}

episodic_end() {
    DATE_TIME=$(date +%Y-%m-%dT%H:%M:%S)
    echo "{\"timestamp\":\"${DATE_TIME}\",\"type\":\"session_end\"}" >> "$SESSION_FILE"
    echo "[Memory] Session ended"

    # Check if consolidation needed before shutdown
    python3 -c "
import sys
sys.path.insert(0, '$(pwd)')
try:
    from memory.consolidation import maybe_consolidate
    result = maybe_consolidate()
    if result.get('triggered'):
        print(f'[Memory] Consolidation triggered on session end: {result}')
except Exception as e:
    print(f'[Memory] Consolidation check failed: {e}')
" 2>/dev/null || echo "[Memory] Consolidation check: python not available"
}

case "${1:-}" in
  start) episodic_start ;;
  end) episodic_end ;;
  *)
    echo "Usage: memory-auto.sh start|end"
    ;;
esac
