#!/bin/bash
# Static readiness doctor for native Claude Code /goal usage.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="static"
JSON_ONLY=0

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/goal-mode-doctor.sh [--static] [--json]

Checks committed, no-secret harness compatibility with native Claude Code /goal.
This doctor never sets /goal, never runs claude -p, never starts Remote Control,
never opens Agent View, never dispatches --bg, and never reads transcripts,
~/.claude/jobs, local Claude profiles, or .env files.
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
NATIVE_GOAL_SKILL = ROOT / ".claude" / "skills" / "goal" / "SKILL.md"
OBSERVED_VERSION = (2, 1, 139)
OBSERVED_VERSION_TEXT = "2.1.139"

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
    "https://code.claude.com/docs/en/goal",
    "https://code.claude.com/docs/en/commands",
    "https://code.claude.com/docs/en/cli-reference",
    "https://code.claude.com/docs/en/hooks",
    "https://code.claude.com/docs/en/permission-modes",
    "https://code.claude.com/docs/en/agent-view",
    "https://code.claude.com/docs/en/agents",
    "https://code.claude.com/docs/en/remote-control",
    "https://code.claude.com/docs/en/headless",
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


checks: list[dict[str, Any]] = []
warnings: list[str] = []
blockers: list[str] = []
settings: dict[str, Any] = {}

if NATIVE_GOAL_SKILL.exists():
    checks.append(check("native-goal-skill-shadow", "fail", "Project skill .claude/skills/goal/SKILL.md would shadow or confuse native /goal", rel(NATIVE_GOAL_SKILL)))
    blockers.append("project_goal_skill_shadows_native_goal")
else:
    checks.append(check("native-goal-skill-shadow", "pass", "No project /goal skill shadows native Claude Code /goal"))

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
    auth_warnings = [name for name in AUTH_OR_PROVIDER_WARNINGS if name in env]
    if auth_warnings:
        checks.append(
            check(
                "shared-env-auth-provider-warnings",
                "warn",
                "Shared settings set provider/auth variables; /goal runtime proof should not be documented as API-key-only",
                {"variables_present": auth_warnings},
            )
        )
        warnings.append("shared_settings_contain_auth_or_provider_variables")
    else:
        checks.append(check("shared-env-auth-provider-warnings", "pass", "Shared settings do not set provider/auth variables"))

disable_all_hooks = settings.get("disableAllHooks") is True if isinstance(settings, dict) else False
if disable_all_hooks:
    checks.append(check("disable-all-hooks", "fail", "disableAllHooks=true blocks native /goal hook behavior"))
    blockers.append("disableAllHooks")
else:
    checks.append(check("disable-all-hooks", "pass", "Shared settings do not disable hooks"))

hooks = settings.get("hooks", {}) if isinstance(settings, dict) else {}
if not isinstance(hooks, dict) or not hooks:
    checks.append(check("hook-wiring-present", "fail", "Shared settings do not define hook wiring"))
    blockers.append("missing_hook_wiring")
else:
    required_hook_groups = ["PreToolUse", "Stop", "SubagentStop", "UserPromptSubmit", "SessionStart"]
    missing_hook_groups = [name for name in required_hook_groups if name not in hooks]
    if missing_hook_groups:
        checks.append(check("hook-wiring-present", "warn", "Some expected governance hook groups are missing", {"missing": missing_hook_groups}))
        warnings.append("incomplete_hook_wiring")
    else:
        checks.append(check("hook-wiring-present", "pass", "Shared settings include governance and temporal hook wiring"))

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
            "Trusted-local bypassPermissions is high-risk for unattended /goal loops",
            {"defaultMode": permission_posture},
        )
    )
    warnings.append("trusted_local_bypassPermissions_goal_loop_risk")
else:
    checks.append(check("permission-posture", "pass", "Permission posture is not bypassPermissions", {"defaultMode": permission_posture}))

process_present = [name for name in AUTH_OR_PROVIDER_WARNINGS if name in os.environ]
if process_present:
    checks.append(
        check(
            "process-env-goal-mode-warnings",
            "warn",
            "Current process environment contains variables relevant to /goal provider/auth troubleshooting",
            {"variables_present": process_present},
        )
    )
    warnings.append("process_env_contains_goal_or_auth_variables")
else:
    checks.append(check("process-env-goal-mode-warnings", "pass", "Current process environment does not expose known /goal auth/provider variables by name"))

claude_bin = shutil.which("claude")
parsed_version: tuple[int, int, int] | None = None
raw_version = ""
help_available = False

if not claude_bin:
    checks.append(check("claude-cli-present", "warn", "claude command not found; native /goal runtime cannot be checked"))
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
        elif parsed_version >= OBSERVED_VERSION:
            checks.append(
                check(
                    "claude-cli-version",
                    "pass",
                    "Claude Code CLI version is at or above observed /goal launch version",
                    {"version": version_text(parsed_version), "minimum_observed_launch_version": OBSERVED_VERSION_TEXT},
                )
            )
        else:
            checks.append(
                check(
                    "claude-cli-version",
                    "warn",
                    "Claude Code CLI is below the observed /goal launch version",
                    {"version": version_text(parsed_version), "minimum_observed_launch_version": OBSERVED_VERSION_TEXT},
                )
            )
            warnings.append("claude_cli_below_observed_goal_launch_version")
            blockers.append("claude_cli_below_observed_goal_launch_version")

    try:
        proc = subprocess.run(
            [claude_bin, "--help"],
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
        )
        help_text = (proc.stdout or proc.stderr or "").strip()
        help_available = bool(help_text)
    except Exception as exc:
        checks.append(check("claude-cli-help", "warn", f"Could not inspect claude --help: {exc}"))
        warnings.append("claude_cli_help_unavailable")
    else:
        if help_available:
            checks.append(check("claude-cli-help", "pass", "claude --help is inspectable without launching a session"))
        else:
            checks.append(check("claude-cli-help", "warn", "claude --help returned no recognizable output"))
            warnings.append("claude_cli_help_empty")

has_failures = any(item.get("status") == "fail" for item in checks)
if has_failures:
    status = "fail"
elif warnings:
    status = "warn"
else:
    status = "pass"

if parsed_version is not None and parsed_version < OBSERVED_VERSION:
    runtime_goal_proof_status = "blocked_by_cli_version"
elif parsed_version is not None and parsed_version >= OBSERVED_VERSION and not has_failures:
    runtime_goal_proof_status = "ready_static_only"
elif parsed_version is None:
    runtime_goal_proof_status = "local_runtime_unproven"
else:
    runtime_goal_proof_status = "not_run_static_only"

artifact = {
    "artifact_type": "goal-mode-readiness",
    "status": status,
    "mode": MODE,
    "native_claude_code_goal": True,
    "native_goal_shadowed_by_project_skill": NATIVE_GOAL_SKILL.exists(),
    "runtime_goal_started": False,
    "runtime_goal_proof_status": runtime_goal_proof_status,
    "cli_version": version_text(parsed_version),
    "official_minimum_required_version": None,
    "minimum_observed_launch_version": OBSERVED_VERSION_TEXT,
    "operator_boundary": "manual_or_bounded_runtime_only",
    "goal_evaluator_is_verifier": False,
    "goal_evaluator_runs_tools": False,
    "requires_hooks_available": True,
    "requires_workspace_trust_runtime": True,
    "works_with_print_mode_doc_claim": True,
    "works_with_remote_control_doc_claim": True,
    "permission_posture": permission_posture,
    "custom_goal_skill_created": False,
    "goal_replaces_opusworkflow": False,
    "goal_replaces_parallel": False,
    "goal_replaces_verify": False,
    "goal_claims_ci_safe_by_default": False,
    "trusted_local_bypass_goal_loop_safe": False,
    "agent_view_rows_are_parent_verified": False,
    "remote_control_goal_cloud_durable": False,
    "provider_identity_proven_by_goal": False,
    "manual_runtime_evidence_required": True,
    "safe_goal_template": {
        "condition": "/goal bash scripts/release-check.sh --static-only exits 0 and git diff --check exits 0, or stop after 6 turns with a blocker summary",
        "bounded_condition": True,
        "command_evidence_required": True,
        "max_turn_or_stop_bound_required": True,
        "parent_verification_required": True,
    },
    "goal_assist_template": {
        "mode": "copy_paste_template_only",
        "runtime_goal_started": False,
        "exact_command_required": True,
        "owned_scope_required": True,
        "forbidden_paths_required": True,
        "transcript_evidence_required": True,
        "stop_bound_required": True,
        "parent_verification_required": True,
        "manual_runtime_evidence_required": True,
    },
    "commands": [
        "/goal <condition>",
        "/goal",
        "/goal clear",
        "claude -p --max-turns 2 --no-session-persistence \"/goal <toy condition or stop after 1 turn>\"",
    ],
    "secrets": {
        "read_secret_files": False,
        "read_local_claude_profiles": False,
        "read_claude_jobs": False,
        "read_transcripts": False,
        "secret_values_redacted": True,
        "tokens_in_url": False,
    },
    "source_ledger": OFFICIAL_SOURCES,
    "blockers": sorted(set(blockers)),
    "warnings": sorted(set(warnings)),
    "checks": checks,
}

if JSON_ONLY:
    print(json.dumps(artifact, indent=2, sort_keys=True))
else:
    print(f"[goal-mode-doctor] status={status} mode={MODE} runtime_goal_proof_status={runtime_goal_proof_status}")
    if blockers:
        print("[goal-mode-doctor] blockers=" + ",".join(sorted(set(blockers))))
    if warnings:
        print("[goal-mode-doctor] warnings=" + ",".join(sorted(set(warnings))))

raise SystemExit(1 if has_failures else 0)
PY
