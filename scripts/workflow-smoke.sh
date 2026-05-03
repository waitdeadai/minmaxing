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
        "/workflow This is a harness contract smoke test. Even though the implementation is tiny, treat it as full file-changing work and follow the full metacognitive route -> research -> code audit -> introspection -> plan -> Agent-Native Estimate -> SPEC.md -> execute -> introspection -> verify flow. In the workflow artifact, include ## Metacognitive Route before ## Research Brief, record the effective parallel budget, and state that the metacognitive route does not satisfy later introspection gates. SPEC.md must exist on disk before editing note.txt. Create note.txt containing ok. Keep everything local and do not push or deploy anything external."
    )"

    echo "$OUTPUT"

    RESEARCH_LINE="$(printf '%s\n' "$OUTPUT" | grep -Eo "(Research Tracks Used|Research)[^[:cntrl:]]*[0-9]+ ?/ ?[0-9]+[^[:cntrl:]]*" | head -n 1 || true)"
    if [ -n "$RESEARCH_LINE" ]; then
        python3 - "$RESEARCH_LINE" <<'PY'
import re
import sys

line = sys.argv[1]
match = re.search(r'(\d+)\s*/\s*(\d+)', line)
if not match:
    raise SystemExit(1)

completed, planned = map(int, match.groups())
if not (0 <= completed <= planned <= 10):
    raise SystemExit(1)
PY
    fi
    echo "$OUTPUT" | grep -Eqi "Code Audit[^[:cntrl:]]*completed"
    echo "$OUTPUT" | grep -Eqi "Plan[^[:cntrl:]]*completed"
    echo "$OUTPUT" | grep -Eqi "SPEC\\.md[^[:cntrl:]]*(created|updated|reused)"
    echo "$OUTPUT" | grep -Eqi "Workflow Artifact[^[:cntrl:]]*\\.taste/workflow-runs/|\\.taste/workflow-runs/"
    test -f "$TMPDIR/SPEC.md"
    test -f "$TMPDIR/note.txt"
    test "$(cat "$TMPDIR/note.txt")" = "ok"
    grep -q "^## Codebase Anchors$" "$TMPDIR/SPEC.md"

    ARTIFACT="$(find "$TMPDIR/.taste/workflow-runs" -maxdepth 1 -type f | head -n 1)"
    test -n "$ARTIFACT"

    awk '
        /^## Metacognitive Route$/ { route = NR }
        /^## Research Brief$/ { research = NR }
        /^## Code Audit$/ { audit = NR }
        /^## Introspection$/ { introspection = NR }
        /^## Plan$/ { plan = NR }
        /^## Agent-Native Estimate$/ { estimate = NR }
        /^## SPEC Decision$/ { spec = NR }
        END {
            if (route && research && audit && introspection && plan && estimate && spec && route < research && research < audit && audit < introspection && introspection < plan && plan < estimate && estimate < spec) {
                exit 0
            }
            exit 1
        }
    ' "$ARTIFACT"
    grep -Eq "^## Metacognitive Route$" "$ARTIFACT"
    grep -Eqi "Effective Parallel Budget|effective parallel budget" "$ARTIFACT"
    grep -Eqi "not.*introspection|not.*introspect|does not satisfy.*introspect|introspection.*still" "$ARTIFACT"
    grep -Eq "^## Agent-Native Estimate$" "$ARTIFACT"
    grep -Eqi "Agent wall-clock|agent-native wall-clock" "$ARTIFACT"
    grep -Eqi "Investigation Mode|Research Mode" "$ARTIFACT"
    grep -Eqi "Research Tracks Used|Research tracks" "$ARTIFACT"
    grep -Eq "^## Introspection$" "$ARTIFACT"
    grep -Eqi "0 ?/ ?0|0 external|local-only|no external search needed|no external research needed|no external facts needed|local file creation|source ledger" "$ARTIFACT"
)

echo "[workflow-smoke] PASS"
