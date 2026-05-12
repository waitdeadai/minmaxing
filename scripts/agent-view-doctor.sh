#!/bin/bash
# Static readiness doctor for Claude Code Agent View.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="static"
JSON_ONLY=0

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/agent-view-doctor.sh [--static] [--json]

Checks committed, no-secret harness compatibility with Claude Code Agent View.
This doctor never starts `claude agents`, never dispatches `claude --bg`, and
never reads session transcripts or ~/.claude/jobs.
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
MIN_VERSION = (2, 1, 139)
MIN_VERSION_TEXT = "2.1.139"

AGENT_VIEW_BLOCKERS = [
    "CLAUDE_CODE_DISABLE_AGENT_VIEW",
]

AUTH_OR_PROVIDER_WARNINGS = [
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

OFFICIAL_SOURCES = [
    "https://code.claude.com/docs/en/agent-view",
    "https://code.claude.com/docs/en/agents",
    "https://code.claude.com/docs/en/permissions",
    "https://claude.com/blog/agent-view-in-claude-code",
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


def version_text(version: tuple[int, int, int] | None) -> str | None:
    if version is None:
        return None
    return ".".join(str(part) for part in version)


def help_kind(help_text: str) -> str:
    lowered = help_text.lower()
    if "background session" in lowered or "agent view" in lowered or "attach <id>" in lowered:
        return "agent_view"
    if "list configured agents" in lowered:
        return "configured_agents_legacy"
    if not help_text.strip():
        return "unknown"
    return "unrecognized"


checks: list[dict[str, Any]] = []
warnings: list[str] = []
blockers: list[str] = []
settings: dict[str, Any] = {}

if not SETTINGS_PATH.is_file():
    checks.append(check("shared-settings-present", "fail", "Missing .claude/settings.json"))
    blockers.append("missing_shared_settings")
else:
    try:
        settings = json.loads(SETTINGS_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        checks.append(check("shared-settings-json", "fail", f"Invalid JSON: {exc}"))
        blockers.append("invalid_shared_settings_json")
    else:
        checks.append(check("shared-settings-json", "pass", "Shared project settings JSON is valid", rel(SETTINGS_PATH)))

env = settings.get("env", {}) if isinstance(settings, dict) else {}
if not isinstance(env, dict):
    checks.append(check("shared-env-object", "fail", "settings.env must be an object"))
    blockers.append("invalid_shared_env")
    env = {}
else:
    shared_blockers = [name for name in AGENT_VIEW_BLOCKERS if name in env]
    if shared_blockers:
        checks.append(
            check(
                "shared-env-agent-view-blockers",
                "fail",
                "Shared project settings set Agent View blocker variables",
                {"variables_present": shared_blockers},
            )
        )
        blockers.extend(shared_blockers)
    else:
        checks.append(check("shared-env-agent-view-blockers", "pass", "Shared settings do not disable Agent View"))

    auth_warnings = [name for name in AUTH_OR_PROVIDER_WARNINGS if name in env]
    if auth_warnings:
        checks.append(
            check(
                "shared-env-auth-provider-warnings",
                "warn",
                "Shared settings set provider/auth variables; Agent View should not be documented as API-key-only",
                {"variables_present": auth_warnings},
            )
        )
        warnings.append("shared_settings_contain_auth_or_provider_variables")
    else:
        checks.append(check("shared-env-auth-provider-warnings", "pass", "Shared settings do not set provider/auth variables"))

if settings.get("disableAgentView") is True:
    checks.append(check("disable-agent-view-setting", "fail", "disableAgentView=true blocks native Agent View"))
    blockers.append("disableAgentView")
else:
    checks.append(check("disable-agent-view-setting", "pass", "Shared settings do not disable Agent View"))

deny_rules = []
try:
    deny_rules = settings.get("permissions", {}).get("deny", []) if isinstance(settings, dict) else []
except AttributeError:
    deny_rules = []
if not isinstance(deny_rules, list):
    checks.append(check("secret-deny-rules", "fail", "permissions.deny must be a list"))
    blockers.append("invalid_secret_deny_rules")
else:
    missing = [rule for rule in REQUIRED_DENY_RULES if rule not in deny_rules]
    if missing:
        checks.append(check("secret-deny-rules", "fail", "Shared settings are missing required secret-read deny rules", {"missing": missing}))
        blockers.extend(f"missing_deny:{rule}" for rule in missing)
    else:
        checks.append(check("secret-deny-rules", "pass", "Shared settings deny .env, local Claude settings, and secrets paths"))

permission_posture = str(settings.get("permissions", {}).get("defaultMode", "unknown")) if isinstance(settings, dict) else "unknown"
if permission_posture == "bypassPermissions":
    checks.append(
        check(
            "permission-posture",
            "warn",
            "Trusted-local bypassPermissions is high-risk for unattended background sessions",
            {"defaultMode": permission_posture},
        )
    )
    warnings.append("trusted_local_bypassPermissions_background_session_risk")
else:
    checks.append(check("permission-posture", "pass", "Permission posture is not bypassPermissions", {"defaultMode": permission_posture}))

process_present = [name for name in AGENT_VIEW_BLOCKERS + AUTH_OR_PROVIDER_WARNINGS if name in os.environ]
if process_present:
    checks.append(
        check(
            "process-env-agent-view-warnings",
            "warn",
            "Current process environment contains variables relevant to Agent View/auth troubleshooting",
            {"variables_present": process_present},
        )
    )
    warnings.append("process_env_contains_agent_view_or_auth_variables")
else:
    checks.append(check("process-env-agent-view-warnings", "pass", "Current process environment does not expose known Agent View blockers by name"))

claude_bin = shutil.which("claude")
parsed_version: tuple[int, int, int] | None = None
raw_version = ""
agents_help = ""
agents_help_kind = "unknown"

if not claude_bin:
    checks.append(check("claude-cli-present", "warn", "claude command not found; Agent View runtime cannot be checked"))
    warnings.append("claude_cli_missing")
else:
    checks.append(check("claude-cli-present", "pass", "claude command found", claude_bin))
    try:
        proc = subprocess.run(
            [claude_bin, "--version"],
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
        )
        raw_version = (proc.stdout or proc.stderr or "").strip()
        parsed_version = parse_version(raw_version)
    except Exception as exc:
        checks.append(check("claude-cli-version", "warn", f"Could not execute claude --version: {exc}"))
        warnings.append("claude_cli_version_unknown")
    else:
        if parsed_version is None:
            checks.append(check("claude-cli-version", "warn", "Could not parse claude --version output", {"raw": raw_version}))
            warnings.append("claude_cli_version_unparsed")
        elif parsed_version >= MIN_VERSION:
            checks.append(
                check(
                    "claude-cli-version",
                    "pass",
                    "Claude Code CLI version is at or above Agent View minimum",
                    {"version": version_text(parsed_version), "minimum": MIN_VERSION_TEXT},
                )
            )
        else:
            checks.append(
                check(
                    "claude-cli-version",
                    "warn",
                    "Claude Code CLI is below the Agent View minimum",
                    {"version": version_text(parsed_version), "minimum": MIN_VERSION_TEXT},
                )
            )
            warnings.append("claude_cli_below_agent_view_minimum")
            blockers.append("claude_cli_below_agent_view_minimum")

    try:
        proc = subprocess.run(
            [claude_bin, "agents", "--help"],
            text=True,
            capture_output=True,
            timeout=8,
            check=False,
        )
        agents_help = (proc.stdout or proc.stderr or "").strip()
        agents_help_kind = help_kind(agents_help)
    except Exception as exc:
        checks.append(check("claude-agents-help", "warn", f"Could not inspect claude agents --help: {exc}"))
        warnings.append("claude_agents_help_unavailable")
    else:
        if agents_help_kind == "agent_view":
            checks.append(check("claude-agents-help", "pass", "claude agents help appears to describe Agent View/background sessions"))
        elif agents_help_kind == "configured_agents_legacy":
            checks.append(
                check(
                    "claude-agents-help",
                    "warn",
                    "claude agents help still describes configured agents, not Agent View",
                    {"help_kind": agents_help_kind},
                )
            )
            warnings.append("claude_agents_help_legacy_configured_agents")
            blockers.append("claude_agents_help_not_agent_view")
        else:
            checks.append(
                check(
                    "claude-agents-help",
                    "warn",
                    "claude agents help did not clearly prove Agent View semantics",
                    {"help_kind": agents_help_kind},
                )
            )
            warnings.append("claude_agents_help_unrecognized")

has_failures = any(item.get("status") == "fail" for item in checks)
if has_failures:
    status = "fail"
elif warnings:
    status = "warn"
else:
    status = "pass"

if parsed_version is not None and parsed_version < MIN_VERSION:
    runtime_proof_status = "blocked_by_cli_version"
elif agents_help_kind == "agent_view" and not has_failures:
    runtime_proof_status = "ready_static_only"
else:
    runtime_proof_status = "not_run_static_only"

artifact = {
    "artifact_type": "agent-view-readiness",
    "status": status,
    "mode": MODE,
    "native_claude_code_agent_view": True,
    "runtime_agent_view_started": False,
    "runtime_background_session_dispatched": False,
    "runtime_proof_status": runtime_proof_status,
    "minimum_required_version": MIN_VERSION_TEXT,
    "cli_version": version_text(parsed_version),
    "claude_agents_help_kind": agents_help_kind,
    "operator_boundary": "manual_operator_monitor_only",
    "permission_posture": permission_posture,
    "custom_web_ui_or_proxy": False,
    "api_key_only_auth_allowed": False,
    "manual_runtime_evidence_required": True,
    "agent_view_equals_remote_control": False,
    "agent_view_replaces_parallel": False,
    "background_sessions_cloud_durable": False,
    "linear_parallel_speedup_claim": False,
    "commands": [
        "claude agents",
        "claude --bg \"<prompt>\"",
        "claude attach <id>",
        "claude logs <id>",
        "claude stop <id>",
        "claude respawn --all",
    ],
    "auth": {
        "requires_paid_claude_code_access": True,
        "api_key_only_supported": False,
        "uses_interactive_claude_code_credentials": True,
    },
    "session_model": {
        "local_supervisor_process": True,
        "sessions_report_only_to_operator": True,
        "subagents_report_to_parent_conversation": True,
        "may_use_claude_worktrees": True,
        "stops_on_sleep_or_shutdown": True,
    },
    "secrets": {
        "read_secret_files": False,
        "read_claude_jobs": False,
        "read_transcripts": False,
        "secret_values_redacted": True,
        "tokens_in_url": False,
    },
    "source_ledger": OFFICIAL_SOURCES,
    "shared_project_env_blockers": [name for name in AGENT_VIEW_BLOCKERS if name in env],
    "blockers": sorted(set(blockers)),
    "warnings": sorted(set(warnings)),
    "checks": checks,
}

if JSON_ONLY:
    print(json.dumps(artifact, indent=2, sort_keys=True))
else:
    print(f"[agent-view-doctor] status={status} mode={MODE} runtime_proof_status={runtime_proof_status}")
    if blockers:
        print("[agent-view-doctor] blockers=" + ",".join(sorted(set(blockers))))
    if warnings:
        print("[agent-view-doctor] warnings=" + ",".join(sorted(set(warnings))))

raise SystemExit(1 if has_failures else 0)
PY
