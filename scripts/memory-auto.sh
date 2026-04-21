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
}

episodic_end() {
    DATE_TIME=$(date +%Y-%m-%dT%H:%M:%S)
    echo "{\"timestamp\":\"${DATE_TIME}\",\"type\":\"session_end\"}" >> "$SESSION_FILE"
    echo "[Memory] Session ended"
}

case "${1:-}" in
  start) episodic_start ;;
  end) episodic_end ;;
  *)
    echo "Usage: memory-auto.sh start|end"
    ;;
esac
