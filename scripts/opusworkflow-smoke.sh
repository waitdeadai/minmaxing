#!/bin/bash
# Static smoke gate for /opusworkflow definitive routing.

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
require_file ".claude/skills/opussonnet/SKILL.md"
require_file "scripts/opusworkflow.sh"
require_file "scripts/opusminimax.sh"
require_file "scripts/opussonnetworkflow.sh"
require_executable "scripts/opusworkflow.sh"
require_executable "scripts/opussonnetworkflow.sh"

for pattern in \
  "Definitive workflow command" \
  "Opus 4.7 high/xhigh" \
  "verified result, partial result, or blocked repair path" \
  "outcome_policy=verified-partial-or-blocked-with-repair" \
  "/opusminimax is the advanced engine" \
  "Use /opusworkflow unless you are debugging the engine" \
  "cost-aware" \
  "MiniMax-M2.7-highspeed is the executor" \
  "Default executor concurrency is 1" \
  "Do not claim Opus planned" \
  "inner_contract=workflow|agentfactory|hiveworkflow|parallel|defineicp|deepretaste|demo|visualizeworkflow" \
  "ANTHROPIC_API_KEY" \
  "80-90% mechanical work"; do
  require_text "$pattern" ".claude/skills/opusworkflow/SKILL.md"
done

for file in README.md CLAUDE.md AGENTS.md scripts/start-session.sh; do
  require_text "/opusworkflow" "$file"
done

require_text "--mode minimax|opusworkflow|opusminimax" setup.sh
require_text "--mode minimax|opusworkflow|opusminimax|opussonnet" setup.sh
require_text 'MODE="opusworkflow"' setup.sh
require_text "--mode opussonnet" README.md
require_text "--import-existing" setup.sh
require_text "MINIMAX_TOKEN_KEY" setup.sh
require_text "TOKEN_KEY" setup.sh
require_text "--minimax-key" setup.sh
require_text "--prompt-minimax-key" setup.sh
require_text "--fix-local-profiles" scripts/opusminimax-doctor.sh
require_text "--inner-contract" scripts/opusworkflow.sh
require_text "planner_identity_status" scripts/opusminimax.sh
require_text "executor_identity_status" scripts/opusminimax.sh
require_text "fallback_status" scripts/opusminimax.sh
require_text "executor_provider" scripts/opusminimax.sh
require_text "model_profile" scripts/opusminimax.sh
require_text "spec_qa" scripts/opusminimax.sh
require_text "spec qa: required after SPEC.md and before implementation" scripts/opusworkflow.sh
require_text "--model-profile" scripts/opusworkflow.sh
require_text "anthropic" scripts/opusworkflow.sh
require_text "claude-sonnet" scripts/opusworkflow.sh
require_text "claude-sonnet-4-6" .claude/settings.opussonnet.example.json
require_text "claude-sonnet-4-6" .claude/settings.sonnet-executor.example.json
require_text "import-manifest.tsv" setup.sh
require_text "skipped_conflicts" setup.sh
require_text "curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --minimax-key 'YOUR_TOKEN_PLAN_KEY'" README.md
require_text "curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --minimax-key 'YOUR_TOKEN_PLAN_KEY'" README.md
require_text "After install, start Claude yourself when you are ready" README.md
require_text "Existing project or harness update" README.md
require_text "Then use the definitive workflow command" README.md
require_text "Both install commands land on the same simple UX: use \`/opusworkflow\`" README.md
require_text "\`/opusminimax\` is the advanced engine underneath" README.md
require_text "verified result, partial result, or blocked repair path" README.md
require_text "inner_contract=workflow|agentfactory|hiveworkflow|parallel|defineicp|deepretaste|demo|visualizeworkflow" README.md
require_text 'Definitive route: /opusworkflow' setup.sh
require_text 'Advanced engine mode selected; normal route remains /opusworkflow.' setup.sh
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
if grep -Fq "Then try: /workflow" setup.sh setup.ps1 README.md 2>/dev/null; then
  fail "default-facing setup/docs must not suggest /workflow as the normal next route"
fi
if grep -Fq "Then try: /opusminimax" setup.sh setup.ps1 README.md 2>/dev/null; then
  fail "default-facing setup/docs must not suggest /opusminimax as the normal next route"
fi

RUN_ID="opusworkflow-smoke"
AGENTFACTORY_RUN_ID="opusworkflow-agentfactory-smoke"
HIVE_RUN_ID="opusworkflow-hiveworkflow-smoke"
SONNET_RUN_ID="opusworkflow-sonnet-smoke"
ALL_SONNET_RUN_ID="opusworkflow-all-sonnet-smoke"
ALL_OPUS_RUN_ID="opusworkflow-all-opus-smoke"
RUN_DIR=".taste/opusminimax/$RUN_ID"
AGENTFACTORY_RUN_DIR=".taste/opusminimax/$AGENTFACTORY_RUN_ID"
HIVE_RUN_DIR=".taste/opusminimax/$HIVE_RUN_ID"
SONNET_RUN_DIR=".taste/opusminimax/$SONNET_RUN_ID"
ALL_SONNET_RUN_DIR=".taste/opusminimax/$ALL_SONNET_RUN_ID"
ALL_OPUS_RUN_DIR=".taste/opusminimax/$ALL_OPUS_RUN_ID"
OUT_FILE="$(mktemp)"
cleanup() {
  rm -f "$OUT_FILE"
  rm -rf "$RUN_DIR" "$AGENTFACTORY_RUN_DIR" "$HIVE_RUN_DIR" "$SONNET_RUN_DIR" "$ALL_SONNET_RUN_DIR" "$ALL_OPUS_RUN_DIR"
}
trap cleanup EXIT
rm -rf "$RUN_DIR" "$AGENTFACTORY_RUN_DIR" "$HIVE_RUN_DIR" "$SONNET_RUN_DIR" "$ALL_SONNET_RUN_DIR" "$ALL_OPUS_RUN_DIR"

bash scripts/opusworkflow.sh --task "cost optimized smoke" --run-id "$RUN_ID" >"$OUT_FILE"
bash scripts/opusworkflow.sh --task "governed Hermes smoke" --inner-contract agentfactory --run-id "$AGENTFACTORY_RUN_ID" >>"$OUT_FILE"
bash scripts/opusworkflow.sh --task "governed hive smoke" --inner-contract hiveworkflow --run-id "$HIVE_RUN_ID" >>"$OUT_FILE"
bash scripts/opusworkflow.sh --task "optional Sonnet smoke" --executor-provider claude-sonnet --run-id "$SONNET_RUN_ID" >>"$OUT_FILE"
bash scripts/opusworkflow.sh --task "all Sonnet smoke" --model-profile sonnet --run-id "$ALL_SONNET_RUN_ID" >>"$OUT_FILE"
bash scripts/opusworkflow.sh --task "all Opus smoke" --model-profile opus --run-id "$ALL_OPUS_RUN_ID" >>"$OUT_FILE"

[ -f "$RUN_DIR/opusminimax-run.json" ] || fail "opusworkflow did not create run artifact"
[ -f "$RUN_DIR/packets/P1.json" ] || fail "opusworkflow did not create packet"
[ -f "$AGENTFACTORY_RUN_DIR/opusminimax-run.json" ] || fail "opusworkflow did not create agentfactory run artifact"
[ -f "$HIVE_RUN_DIR/opusminimax-run.json" ] || fail "opusworkflow did not create hiveworkflow run artifact"
[ -f "$SONNET_RUN_DIR/opusminimax-run.json" ] || fail "opusworkflow did not create Sonnet run artifact"
[ -f "$ALL_SONNET_RUN_DIR/opusminimax-run.json" ] || fail "opusworkflow did not create all-Sonnet run artifact"
[ -f "$ALL_OPUS_RUN_DIR/opusminimax-run.json" ] || fail "opusworkflow did not create all-Opus run artifact"

python3 - "$RUN_DIR/opusminimax-run.json" "$AGENTFACTORY_RUN_DIR/opusminimax-run.json" "$HIVE_RUN_DIR/opusminimax-run.json" <<'PY'
import json
import pathlib
import sys

expected = ["workflow", "agentfactory", "hiveworkflow"]
for raw_path, contract in zip(sys.argv[1:], expected):
    path = pathlib.Path(raw_path)
    data = json.loads(path.read_text(encoding="utf-8"))
    capacity = data.get("capacity", {})
    models = data.get("model_ids", {})
    assert data.get("artifact_type") == "opusminimax-run"
    assert data.get("outer_route") == "opusworkflow"
    assert data.get("inner_contract") == contract
    assert data.get("outcome_policy") == "verified-partial-or-blocked-with-repair"
    workflow_contract = data.get("workflow_contract", {})
    assert workflow_contract.get("definitive_command") is True
    assert workflow_contract.get("blocked_requires_repair") is True
    assert {"verified", "partial", "blocked"}.issubset(set(workflow_contract.get("allowed_closeout_statuses", [])))
    assert data.get("planner_identity_status") == "blocked"
    assert data.get("executor_identity_status") == "configured"
    assert data.get("fallback_status") == "none"
    assert data.get("model_profile") == "minimax"
    spec_qa = data.get("spec_qa", {})
    assert spec_qa.get("required") is True
    assert spec_qa.get("runs_after_spec_creation") is True
    assert spec_qa.get("before_implementation") is True
    assert spec_qa.get("requested_reviewer") == "claude-opus-4-7"
    assert spec_qa.get("identity_status") == "blocked"
    assert spec_qa.get("claims_opus_review") is False
    assert spec_qa.get("source_ledger_required_for_sota") is True
    assert models.get("executor_requested") == "MiniMax-M2.7-highspeed"
    assert capacity.get("provider_ceiling") == 1
    assert capacity.get("effective_concurrency") == 1
    assert data.get("claims", {}).get("opus_planned") is False
PY

python3 - "$SONNET_RUN_DIR/opusminimax-run.json" <<'PY'
import json
import pathlib
import sys

data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
models = data.get("model_ids", {})
profiles = data.get("provider_profiles", {})
executor = profiles.get("executor", {})
assert data.get("artifact_type") == "opusminimax-run"
assert data.get("outer_route") == "opusworkflow"
assert data.get("model_profile") == "opussonnet"
assert data.get("executor_provider") == "claude-sonnet"
assert models.get("executor_requested") == "claude-sonnet-4-6"
assert executor.get("anthropic_base_url", "") == ""
assert "sonnet" in executor.get("model", "").lower()
assert data.get("claims", {}).get("opus_planned") is False
PY

python3 - "$ALL_SONNET_RUN_DIR/opusminimax-run.json" "$ALL_OPUS_RUN_DIR/opusminimax-run.json" <<'PY'
import json
import pathlib
import sys

sonnet = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
opus = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
for data, profile, needle in [(sonnet, "sonnet", "sonnet"), (opus, "opus", "opus")]:
    models = data.get("model_ids", {})
    executor = data.get("provider_profiles", {}).get("executor", {})
    assert data.get("artifact_type") == "opusminimax-run"
    assert data.get("outer_route") == "opusworkflow"
    assert data.get("model_profile") == profile
    assert data.get("executor_provider") == "anthropic"
    assert needle in models.get("planner_requested", "").lower()
    assert needle in models.get("executor_requested", "").lower()
    assert executor.get("anthropic_base_url", "") == ""
    executor_blob = json.dumps(executor).lower()
    assert "api.minimax.io/anthropic" not in executor_blob
    assert "minimax-m2.7-highspeed" not in executor_blob
    assert data.get("claims", {}).get("opus_planned") is False
PY

bash scripts/artifact-lint.sh "$RUN_DIR/opusminimax-run.json" >/dev/null
bash scripts/artifact-lint.sh "$RUN_DIR/packets/P1.json" >/dev/null
bash scripts/artifact-lint.sh "$AGENTFACTORY_RUN_DIR/opusminimax-run.json" >/dev/null
bash scripts/artifact-lint.sh "$HIVE_RUN_DIR/opusminimax-run.json" >/dev/null
bash scripts/artifact-lint.sh "$SONNET_RUN_DIR/opusminimax-run.json" >/dev/null
bash scripts/artifact-lint.sh "$ALL_SONNET_RUN_DIR/opusminimax-run.json" >/dev/null
bash scripts/artifact-lint.sh "$ALL_OPUS_RUN_DIR/opusminimax-run.json" >/dev/null

echo "[PASS] /opusworkflow definitive route smoke passed"
