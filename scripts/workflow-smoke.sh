#!/bin/bash
# Runtime smoke test for /workflow.
# Requires Claude auth via login or a local settings file with credentials.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS_PATH="${CLAUDE_SETTINGS_PATH:-}"

if [ -z "$SETTINGS_PATH" ] && [ -f "$ROOT_DIR/.claude/settings.local.json" ]; then
    SETTINGS_PATH="$ROOT_DIR/.claude/settings.local.json"
fi

if [ -z "$SETTINGS_PATH" ] && [ -f "$ROOT_DIR/.claude/settings.json" ] && ! grep -q "YOUR_MINIMAX_API_KEY" "$ROOT_DIR/.claude/settings.json"; then
    SETTINGS_PATH="$ROOT_DIR/.claude/settings.json"
fi

if [ -z "$SETTINGS_PATH" ]; then
    echo "[workflow-smoke] SKIP: no authenticated Claude settings file found"
    exit 0
fi

SETTINGS_PATH="$(cd "$(dirname "$SETTINGS_PATH")" && pwd)/$(basename "$SETTINGS_PATH")"

TMPDIR="$(mktemp -d /tmp/minmaxing-workflow-smoke-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.claude"
cp -r "$ROOT_DIR/.claude/skills" "$TMPDIR/.claude/"
cp -r "$ROOT_DIR/.claude/rules" "$TMPDIR/.claude/"
cp -r "$ROOT_DIR/scripts" "$TMPDIR/"
cp -r "$ROOT_DIR/memory" "$TMPDIR/"
cp "$ROOT_DIR/CLAUDE.md" "$TMPDIR/"

cat > "$TMPDIR/taste.md" <<'EOF'
# Taste
- Prefer correctness over speed.
- Keep changes minimal and verifiable.
EOF

cat > "$TMPDIR/taste.vision" <<'EOF'
# Vision
Use minmaxing as a correctness-first Claude Code harness.
EOF

cat > "$TMPDIR/README.md" <<'EOF'
# Smoke Repo
EOF

(
    cd "$TMPDIR"
    git init -q
    git config user.email smoke@example.com
    git config user.name smoke

    OUTPUT="$(
        claude -p --settings "$SETTINGS_PATH" \
        "/workflow build a tiny local smoke test by creating note.txt containing ok. Keep everything local and do not push or deploy anything external."
    )"

    echo "$OUTPUT"

    test -f "$TMPDIR/SPEC.md"
    test -f "$TMPDIR/note.txt"
    test "$(cat "$TMPDIR/note.txt")" = "ok"
)

echo "[workflow-smoke] PASS"
