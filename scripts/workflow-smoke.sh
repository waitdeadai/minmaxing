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
if [ "${KEEP_WORKFLOW_SMOKE_DIR:-0}" = "1" ]; then
    echo "[workflow-smoke] keeping tmpdir: $TMPDIR"
else
    trap 'rm -rf "$TMPDIR"' EXIT
fi

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
        MAX_PARALLEL_AGENTS=10 claude -p --settings "$SETTINGS_PATH" \
        "/workflow build a tiny local smoke test by creating note.txt containing ok. Keep everything local and do not push or deploy anything external."
    )"

    echo "$OUTPUT"

    echo "$OUTPUT" | grep -Eq "Research[^[:cntrl:]]*completed with MiniMax MCP"
    echo "$OUTPUT" | grep -Eq "Research Tracks Used[^[:cntrl:]]*10 ?/ ?10"
    echo "$OUTPUT" | grep -Eq "MiniMax MCP Searches[^[:cntrl:]]*10"
    echo "$OUTPUT" | grep -Eq "Code Audit[^[:cntrl:]]*completed"
    echo "$OUTPUT" | grep -Eq "Plan[^[:cntrl:]]*completed"
    echo "$OUTPUT" | grep -Eq "Workflow Artifact[^[:cntrl:]]*\\.taste/workflow-runs/"
    test -f "$TMPDIR/SPEC.md"
    test -f "$TMPDIR/note.txt"
    test "$(cat "$TMPDIR/note.txt")" = "ok"
    grep -q "^## Codebase Anchors$" "$TMPDIR/SPEC.md"

    ARTIFACT="$(find "$TMPDIR/.taste/workflow-runs" -maxdepth 1 -type f | head -n 1)"
    test -n "$ARTIFACT"

    awk '
        /^## Research Brief$/ { research = NR }
        /^## Code Audit$/ { audit = NR }
        /^## Plan$/ { plan = NR }
        /^## SPEC Decision$/ { spec = NR }
        END {
            if (research && audit && plan && spec && research < audit && audit < plan && plan < spec) {
                exit 0
            }
            exit 1
        }
    ' "$ARTIFACT"
)

echo "[workflow-smoke] PASS"
