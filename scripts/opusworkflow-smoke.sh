#!/bin/bash
# Static smoke gate for /opusworkflow cost-optimized routing.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing required file: $1"
}

require_executable() {
  [ -x "$1" ] || fail "required script is not executable: $1"
}

require_text() {
  local pattern="$1"
  local file="$2"
  grep -Fq -- "$pattern" "$file" 2>/dev/null || fail "missing pattern '$pattern' in $file"
}

require_file ".claude/skills/opusworkflow/SKILL.md"
require_file ".claude/skills/opusminimax/SKILL.md"
require_file "scripts/opusworkflow.sh"
require_file "scripts/opusminimax.sh"
require_executable "scripts/opusworkflow.sh"

for pattern in \
  "cost-optimized" \
  "MiniMax-M2.7-highspeed is the executor" \
  "Default executor concurrency is 1" \
  "Do not claim Opus planned" \
  "ANTHROPIC_API_KEY" \
  "80-90% mechanical work"; do
  require_text "$pattern" ".claude/skills/opusworkflow/SKILL.md"
done

for file in README.md CLAUDE.md AGENTS.md scripts/start-session.sh; do
  require_text "/opusworkflow" "$file"
done

require_text "--mode minimax|opusworkflow|opusminimax" setup.sh
require_text 'MODE="opusworkflow"' setup.sh
require_text "--import-existing" setup.sh
require_text "MINIMAX_TOKEN_KEY" setup.sh
require_text "TOKEN_KEY" setup.sh
require_text "--minimax-key" setup.sh
require_text "--prompt-minimax-key" setup.sh
require_text "import-manifest.tsv" setup.sh
require_text "skipped_conflicts" setup.sh
require_text "MINIMAX_TOKEN_KEY='YOUR_TOKEN_PLAN_KEY' bash -lc 'curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash && claude'" README.md
require_text "MINIMAX_TOKEN_KEY='YOUR_TOKEN_PLAN_KEY' bash -lc 'curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing && claude'" README.md
require_text "Existing project or harness update" README.md
require_text "Both commands default to \`/opusworkflow\`" README.md
require_text 'Default route: /opusworkflow' setup.sh
require_text '$Mode = "opusworkflow"' setup.ps1
require_text "settings.minimax-executor.local.json" setup.ps1
require_text "settings.opusminimax-planner.local.json" setup.ps1
require_text "Split mode does not mutate user-scope MCP automatically" setup.ps1
require_text "opusworkflow-smoke" scripts/harness-eval.sh
require_text "opusworkflow-smoke" scripts/release-check.sh
require_text "opusworkflow" scripts/harness-capability-map.sh

HELP_OUTPUT="$(env -u MINIMAX_TOKEN_KEY -u TOKEN_KEY bash setup.sh --help)"
printf '%s' "$HELP_OUTPUT" | grep -Fq "(default: opusworkflow)" || fail "setup --help must show opusworkflow as the default"
if printf '%s' "$HELP_OUTPUT" | grep -Fq "[0/7]"; then
  fail "setup --help must not execute the installer"
fi

RUN_ID="opusworkflow-smoke"
RUN_DIR=".taste/opusminimax/$RUN_ID"
OUT_FILE="$(mktemp)"
cleanup() {
  rm -f "$OUT_FILE"
  rm -rf "$RUN_DIR"
}
trap cleanup EXIT
rm -rf "$RUN_DIR"

bash scripts/opusworkflow.sh --task "cost optimized smoke" --run-id "$RUN_ID" >"$OUT_FILE"

[ -f "$RUN_DIR/opusminimax-run.json" ] || fail "opusworkflow did not create run artifact"
[ -f "$RUN_DIR/packets/P1.json" ] || fail "opusworkflow did not create packet"

python3 - "$RUN_DIR/opusminimax-run.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
capacity = data.get("capacity", {})
models = data.get("model_ids", {})
assert data.get("artifact_type") == "opusminimax-run"
assert models.get("executor_requested") == "MiniMax-M2.7-highspeed"
assert capacity.get("provider_ceiling") == 1
assert capacity.get("effective_concurrency") == 1
assert data.get("claims", {}).get("opus_planned") is False
PY

bash scripts/artifact-lint.sh "$RUN_DIR/opusminimax-run.json" >/dev/null
bash scripts/artifact-lint.sh "$RUN_DIR/packets/P1.json" >/dev/null

echo "[PASS] /opusworkflow cost-optimized smoke passed"
