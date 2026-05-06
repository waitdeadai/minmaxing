#!/bin/bash
# Validate and optionally execute a bounded MiniMax executor packet.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKET=""
RUN_DIR=""
EXECUTE=0
SETTINGS_PATH="${CLAUDE_SETTINGS_PATH:-$ROOT_DIR/.claude/settings.minimax-executor.local.json}"

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/minimax-exec.sh --packet packet.json --run-dir .taste/opusminimax/RUN_ID [--execute] [--settings PATH]

Default behavior is static packet validation plus a dry execution sidecar.
--execute is the explicit provider-runtime opt-in.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--packet")
      PACKET="${2:-}"
      shift 2
      ;;
    "--run-dir")
      RUN_DIR="${2:-}"
      shift 2
      ;;
    "--settings")
      SETTINGS_PATH="${2:-}"
      shift 2
      ;;
    "--execute")
      EXECUTE=1
      shift
      ;;
    "-h"|"--help")
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[ -n "$PACKET" ] || { usage; exit 2; }
[ -n "$RUN_DIR" ] || { usage; exit 2; }

mkdir -p "$RUN_DIR/executor-results"

bash "$ROOT_DIR/scripts/artifact-lint.sh" "$PACKET"

RESULT_PATH="$RUN_DIR/executor-results/$(basename "${PACKET%.json}")-result.json"

if [ "$EXECUTE" -eq 0 ]; then
  python3 - "$PACKET" "$RESULT_PATH" <<'PY'
import json
import pathlib
import sys

packet_path = pathlib.Path(sys.argv[1])
result_path = pathlib.Path(sys.argv[2])
packet = json.loads(packet_path.read_text(encoding="utf-8"))
payload = {
    "artifact_type": "worker-result",
    "packet_id": packet["packet_id"],
    "owner": "minimax-executor",
    "owned_files": packet["owned_paths"],
    "touched_files": packet["owned_paths"][:1],
    "commands_run": [{"command": f"bash scripts/minimax-exec.sh --packet {packet_path} --run-dir {result_path.parent.parent}", "status": "pass"}],
    "evidence": ["packet validated; provider runtime not executed"],
    "claims": [{"claim": "packet is valid and ready for explicit --execute runtime", "verified": True}],
    "parent_verified": True,
    "execution_status": "dry-run",
}
result_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"[minimax-exec] dry-run sidecar: {result_path}")
PY
  exit 0
fi

if [ ! -f "$SETTINGS_PATH" ]; then
  echo "[minimax-exec] missing executor settings: $SETTINGS_PATH" >&2
  echo "[minimax-exec] copy .claude/settings.minimax-executor.example.json to an ignored local profile first" >&2
  exit 1
fi

python3 - "$SETTINGS_PATH" <<'PY'
import json
import pathlib
import sys

settings = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
env = settings.get("env", {})
if env.get("ANTHROPIC_BASE_URL") != "https://api.minimax.io/anthropic":
    raise SystemExit("executor settings must use MiniMax Anthropic-compatible base URL")
if "MiniMax-M2.7-highspeed" not in json.dumps(env):
    raise SystemExit("executor settings must request MiniMax-M2.7-highspeed")
if env.get("ANTHROPIC_AUTH_TOKEN") == "YOUR_MINIMAX_API_KEY":
    raise SystemExit("executor settings still contain the placeholder token")
PY

PROMPT="$(python3 - "$PACKET" <<'PY'
import json
import pathlib
import sys

packet = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
print(
    "/opusminimax executor packet\n"
    "You are MiniMax-M2.7-highspeed executing one bounded packet. "
    "Touch only owned paths, stop on forbidden paths, and report command evidence.\n\n"
    + json.dumps(packet, indent=2, sort_keys=True)
)
PY
)"

claude -p --settings "$SETTINGS_PATH" "$PROMPT" | tee "$RESULT_PATH.txt"
echo "[minimax-exec] runtime transcript: $RESULT_PATH.txt"
