#!/bin/bash
# Static readiness doctor for Claude Code native Remote Control.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="static"
JSON_ONLY=0

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/remote-control-doctor.sh [--static] [--json]

Checks committed, no-secret harness compatibility with Claude Code native
Remote Control. This doctor never starts `claude remote-control`.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--static")
      MODE="static"
      shift
      ;;
    "--json")
      JSON_ONLY=1
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

python3 - "$ROOT_DIR" "$MODE" "$JSON_ONLY" <<'PY'
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
MODE = sys.argv[2]
JSON_ONLY = sys.argv[3] == "1"
SETTINGS_PATH = ROOT / ".claude" / "settings.json"

SHARED_BLOCKERS = [
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",
    "DISABLE_TELEMETRY",
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_AUTH_TOKEN",
    "CLAUDE_CODE_OAUTH_TOKEN",
    "CLAUDE_CODE_USE_BEDROCK",
    "CLAUDE_CODE_USE_VERTEX",
    "CLAUDE_CODE_USE_FOUNDRY",
]

PROCESS_WARNINGS = [
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",
    "DISABLE_TELEMETRY",
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_AUTH_TOKEN",
    "CLAUDE_CODE_OAUTH_TOKEN",
    "CLAUDE_CODE_USE_BEDROCK",
    "CLAUDE_CODE_USE_VERTEX",
    "CLAUDE_CODE_USE_FOUNDRY",
]

REQUIRED_DENY_RULES = [
    "Read(./.env)",
    "Read(./.env.*)",
    "Read(./.claude/settings.local.json)",
    "Read(./.claude/*.local.json)",
    "Read(./secrets/**)",
]


def rel(path: pathlib.Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def check(check_id: str, status: str, summary: str, evidence: Any = None) -> dict[str, Any]:
    item: dict[str, Any] = {
        "id": check_id,
        "status": status,
        "summary": summary,
    }
    if evidence is not None:
        item["evidence"] = evidence
    return item


def parse_version(text: str) -> tuple[int, int, int] | None:
    match = re.search(r"(\d+)\.(\d+)\.(\d+)", text)
    if not match:
        return None
    return tuple(int(part) for part in match.groups())


checks: list[dict[str, Any]] = []
settings: dict[str, Any] = {}

if not SETTINGS_PATH.is_file():
    checks.append(check("shared-settings-present", "fail", "Missing .claude/settings.json"))
else:
    try:
        settings = json.loads(SETTINGS_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        checks.append(check("shared-settings-json", "fail", f"Invalid JSON: {exc}"))
    else:
        checks.append(check("shared-settings-json", "pass", "Shared project settings JSON is valid", rel(SETTINGS_PATH)))

env = settings.get("env", {}) if isinstance(settings, dict) else {}
if not isinstance(env, dict):
    checks.append(check("shared-env-object", "fail", "settings.env must be an object"))
    env = {}
else:
    blockers = [name for name in SHARED_BLOCKERS if name in env]
    if blockers:
        checks.append(
            check(
                "shared-env-blockers",
                "fail",
                "Shared project settings set Remote Control blocker or auth variables",
                {"variables_present": blockers},
            )
        )
    else:
        checks.append(
            check(
                "shared-env-blockers",
                "pass",
                "Shared project settings do not set known Remote Control blocker or provider auth variables",
            )
        )

disable_remote = settings.get("disableRemoteControl") if isinstance(settings, dict) else None
if disable_remote is True:
    checks.append(check("disable-remote-control-setting", "fail", "disableRemoteControl=true blocks native Remote Control"))
else:
    checks.append(check("disable-remote-control-setting", "pass", "Shared settings do not disable native Remote Control"))

deny_rules = []
try:
    deny_rules = settings.get("permissions", {}).get("deny", []) if isinstance(settings, dict) else []
except AttributeError:
    deny_rules = []
if not isinstance(deny_rules, list):
    checks.append(check("secret-deny-rules", "fail", "permissions.deny must be a list"))
else:
    missing = [rule for rule in REQUIRED_DENY_RULES if rule not in deny_rules]
    if missing:
        checks.append(
            check(
                "secret-deny-rules",
                "fail",
                "Shared settings are missing required secret-read deny rules",
                {"missing": missing},
            )
        )
    else:
        checks.append(
            check(
                "secret-deny-rules",
                "pass",
                "Shared settings deny .env, local Claude settings, and secrets paths",
            )
        )

process_present = [name for name in PROCESS_WARNINGS if name in os.environ]
if process_present:
    checks.append(
        check(
            "process-env-remote-control-warnings",
            "warn",
            "Current process environment contains variables that can block a live Remote Control session",
            {"variables_present": process_present},
        )
    )
else:
    checks.append(
        check(
            "process-env-remote-control-warnings",
            "pass",
            "Current process environment does not expose known Remote Control blockers by name",
        )
    )

claude_bin = shutil.which("claude")
version_text = ""
if not claude_bin:
    checks.append(check("claude-cli-version", "warn", "claude command not found; runtime version not checked"))
else:
    try:
        proc = subprocess.run(
            [claude_bin, "--version"],
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
        )
        version_text = (proc.stdout or proc.stderr or "").strip()
    except Exception as exc:
        checks.append(check("claude-cli-version", "warn", f"Could not execute claude --version: {exc}"))
    else:
        parsed = parse_version(version_text)
        if parsed is None:
            checks.append(check("claude-cli-version", "warn", "Could not parse claude --version output"))
        elif parsed >= (2, 1, 51):
            checks.append(
                check(
                    "claude-cli-version",
                    "pass",
                    "Claude Code CLI version is at or above native Remote Control minimum",
                    {"version": ".".join(str(part) for part in parsed)},
                )
            )
        else:
            checks.append(
                check(
                    "claude-cli-version",
                    "warn",
                    "Claude Code CLI may be too old for native Remote Control",
                    {"version": ".".join(str(part) for part in parsed)},
                )
            )

statuses = {item["status"] for item in checks}
overall = "fail" if "fail" in statuses else "warn" if "warn" in statuses else "pass"
payload = {
    "artifact_type": "remote-control-readiness",
    "mode": MODE,
    "status": overall,
    "native_claude_code_remote_control": True,
    "runtime_remote_control_started": False,
    "runtime_proof_status": "not_run_static_only",
    "custom_network_control_plane": False,
    "api_key_auth_allowed": False,
    "auth": {
        "requires_claude_ai_subscription": True,
        "api_keys_supported": False,
        "oauth_login_required": True,
    },
    "commands": [
        "/remote-control",
        "/rc",
        "claude --remote-control",
        "claude remote-control",
    ],
    "shared_project_env_blockers": [name for name in SHARED_BLOCKERS if name in env],
    "process_env_blocker_names_present": process_present,
    "secrets": {
        "read_secret_files": False,
        "tokens_in_url": False,
        "secret_values_redacted": True,
    },
    "operator_stop_required": True,
    "checks": checks,
}

if JSON_ONLY:
    print(json.dumps(payload, indent=2, sort_keys=True))
else:
    print(f"[remote-control-doctor] status={overall} mode={MODE}")
    for item in checks:
        print(f"[{item['status'].upper()}] {item['id']}: {item['summary']}")

raise SystemExit(1 if overall == "fail" else 0)
PY
