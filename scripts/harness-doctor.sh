#!/bin/bash
# Produce one local operator health summary for the minmaxing harness.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="text"
HTML_OUT=""

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/harness-doctor.sh [--json] [--html OUT]

Summarizes local harness health from git status, SPEC.md, Claude settings,
hook mappings, memory health, run metrics, and session insights.

The doctor is local-only. Missing provider cost, token, ACU, or calibration
data is reported as insufficient_data instead of guessed.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--json")
      MODE="json"
      shift
      ;;
    "--html")
      if [ -z "${2:-}" ]; then
        usage
        exit 2
      fi
      HTML_OUT="$2"
      shift 2
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

python3 - "$ROOT_DIR" "$MODE" "$HTML_OUT" <<'PY'
import datetime as dt
import html
import json
import os
import pathlib
import re
import subprocess
import sys
from collections import Counter
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
MODE = sys.argv[2]
HTML_OUT = sys.argv[3]
INSUFFICIENT = "insufficient_data"


def rel(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def run_local(args: list[str], timeout: int = 20) -> dict[str, Any]:
    try:
        proc = subprocess.run(
            args,
            cwd=ROOT,
            text=True,
            capture_output=True,
            timeout=timeout,
            check=False,
        )
        return {
            "command": " ".join(args),
            "exit_code": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
            "timed_out": False,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "command": " ".join(args),
            "exit_code": None,
            "stdout": exc.stdout or "",
            "stderr": exc.stderr or "",
            "timed_out": True,
        }
    except OSError as exc:
        return {
            "command": " ".join(args),
            "exit_code": None,
            "stdout": "",
            "stderr": str(exc),
            "timed_out": False,
        }


def parse_json_command(args: list[str], timeout: int = 30) -> tuple[dict[str, Any], dict[str, Any] | None]:
    result = run_local(args, timeout=timeout)
    if result["exit_code"] != 0:
        return result, None
    try:
        return result, json.loads(result["stdout"])
    except json.JSONDecodeError as exc:
        result["json_error"] = str(exc)
        return result, None


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def script_available(path: pathlib.Path) -> bool:
    return path.is_file() and os.access(path, os.R_OK)


def status_from_memory_output(text: str) -> str:
    for line in text.splitlines():
        match = re.match(r"status:\s*([A-Za-z0-9_-]+)\s*$", line)
        if match:
            return match.group(1)
    return "unknown"


def collect_git() -> dict[str, Any]:
    probe = run_local(["git", "rev-parse", "--is-inside-work-tree"], timeout=5)
    if probe["exit_code"] != 0:
        return {
            "available": False,
            "status": "unavailable",
            "entries": [],
            "dirty_count": 0,
            "error": (probe["stderr"] or probe["stdout"]).strip(),
        }

    status = run_local(["git", "status", "--short"], timeout=10)
    branch = run_local(["git", "branch", "--show-current"], timeout=5)
    head = run_local(["git", "rev-parse", "--short", "HEAD"], timeout=5)
    entries = [line for line in status["stdout"].splitlines() if line.strip()]
    return {
        "available": status["exit_code"] == 0,
        "status": "dirty" if entries else "clean",
        "dirty_count": len(entries),
        "entries": entries,
        "branch": branch["stdout"].strip() if branch["exit_code"] == 0 else "",
        "head": head["stdout"].strip() if head["exit_code"] == 0 else "",
        "command_exit": status["exit_code"],
        "error": status["stderr"].strip(),
    }


def collect_spec() -> dict[str, Any]:
    path = ROOT / "SPEC.md"
    if not path.is_file():
        return {
            "path": "SPEC.md",
            "present": False,
            "has_agent_native_estimate": False,
            "title": "",
            "status": "missing",
        }

    text = read_text(path)
    title = ""
    for line in text.splitlines():
        if line.startswith("# "):
            title = line[2:].strip()
            break
    has_estimate = re.search(r"^##\s+Agent-Native Estimate\s*$", text, re.MULTILINE) is not None
    return {
        "path": "SPEC.md",
        "present": True,
        "has_agent_native_estimate": has_estimate,
        "title": title,
        "status": "healthy" if has_estimate else "attention",
    }


def hook_paths_from_command(command: str) -> list[str]:
    paths = []
    for match in re.finditer(r"(?:\$CLAUDE_PROJECT_DIR/)?(\.claude/hooks/[A-Za-z0-9._/-]+)", command):
        paths.append(match.group(1))
    return sorted(set(paths))


def collect_claude_settings() -> dict[str, Any]:
    path = ROOT / ".claude" / "settings.json"
    if not path.is_file():
        return {
            "path": ".claude/settings.json",
            "present": False,
            "valid_json": False,
            "status": "missing",
            "hook_events": [],
            "hook_mappings": [],
            "referenced_hook_scripts": [],
            "missing_referenced_hook_scripts": [],
            "error": "file missing",
        }

    try:
        data = json.loads(read_text(path))
    except json.JSONDecodeError as exc:
        return {
            "path": ".claude/settings.json",
            "present": True,
            "valid_json": False,
            "status": "invalid",
            "hook_events": [],
            "hook_mappings": [],
            "referenced_hook_scripts": [],
            "missing_referenced_hook_scripts": [],
            "error": str(exc),
        }

    hooks = data.get("hooks", {})
    mappings: list[dict[str, Any]] = []
    referenced: dict[str, bool] = {}

    if isinstance(hooks, dict):
        for event, event_entries in hooks.items():
            if not isinstance(event_entries, list):
                mappings.append(
                    {
                        "event": event,
                        "matcher": "",
                        "type": "invalid",
                        "command": "",
                        "timeout": None,
                        "hook_paths": [],
                    }
                )
                continue
            for entry in event_entries:
                matcher = ""
                hook_entries: list[Any] = []
                if isinstance(entry, dict):
                    matcher = str(entry.get("matcher", ""))
                    hook_entries = entry.get("hooks", [])
                if not isinstance(hook_entries, list):
                    hook_entries = []
                for hook in hook_entries:
                    if not isinstance(hook, dict):
                        continue
                    command = str(hook.get("command", ""))
                    hook_paths = hook_paths_from_command(command)
                    for hook_path in hook_paths:
                        referenced[hook_path] = (ROOT / hook_path).is_file()
                    mappings.append(
                        {
                            "event": event,
                            "matcher": matcher,
                            "type": hook.get("type", ""),
                            "command": command,
                            "timeout": hook.get("timeout"),
                            "hook_paths": hook_paths,
                        }
                    )

    missing = sorted(path for path, exists in referenced.items() if not exists)
    status = "healthy"
    if not isinstance(hooks, dict) or not hooks or not mappings:
        status = "attention"
    if missing:
        status = "unhealthy"

    return {
        "path": ".claude/settings.json",
        "present": True,
        "valid_json": True,
        "status": status,
        "default_mode": data.get("permissions", {}).get("defaultMode")
        if isinstance(data.get("permissions"), dict)
        else None,
        "hook_events": sorted(hooks.keys()) if isinstance(hooks, dict) else [],
        "hook_mapping_count": len(mappings),
        "hook_mappings": mappings,
        "referenced_hook_scripts": [
            {"path": hook_path, "exists": exists}
            for hook_path, exists in sorted(referenced.items())
        ],
        "missing_referenced_hook_scripts": missing,
        "error": "",
    }


def collect_memory() -> dict[str, Any]:
    path = ROOT / "scripts" / "memory.sh"
    if not script_available(path):
        return {
            "available": False,
            "path": "scripts/memory.sh",
            "status": INSUFFICIENT,
            "pass_count": 0,
            "warn_count": 0,
            "fail_count": 0,
            "command_exit": None,
            "summary": "scripts/memory.sh unavailable",
        }

    result = run_local(["bash", "scripts/memory.sh", "health"], timeout=30)
    stdout = result["stdout"]
    return {
        "available": True,
        "path": "scripts/memory.sh",
        "status": status_from_memory_output(stdout),
        "pass_count": len(re.findall(r"^\[PASS\]", stdout, re.MULTILINE)),
        "warn_count": len(re.findall(r"^\[WARN\]", stdout, re.MULTILINE)),
        "fail_count": len(re.findall(r"^\[FAIL\]", stdout, re.MULTILINE)),
        "command_exit": result["exit_code"],
        "timed_out": result["timed_out"],
        "summary": stdout.strip(),
        "error": result["stderr"].strip(),
    }


def summarize_run_metrics() -> dict[str, Any]:
    path = ROOT / "scripts" / "run-metrics.sh"
    if not script_available(path):
        return {
            "available": False,
            "status": INSUFFICIENT,
            "path": "scripts/run-metrics.sh",
            "provider_cost": INSUFFICIENT,
            "provider_tokens": INSUFFICIENT,
            "acu": INSUFFICIENT,
            "estimate_calibration": INSUFFICIENT,
        }

    result, data = parse_json_command(["bash", "scripts/run-metrics.sh", "--json"], timeout=30)
    if data is None:
        return {
            "available": True,
            "status": "unhealthy",
            "path": "scripts/run-metrics.sh",
            "command_exit": result["exit_code"],
            "error": (result.get("json_error") or result["stderr"] or result["stdout"]).strip(),
            "provider_cost": INSUFFICIENT,
            "provider_tokens": INSUFFICIENT,
            "acu": INSUFFICIENT,
            "estimate_calibration": INSUFFICIENT,
        }

    return {
        "available": True,
        "status": "healthy",
        "path": "scripts/run-metrics.sh",
        "command_exit": result["exit_code"],
        "source": data.get("source", ""),
        "workflow_runs": data.get("workflow_runs", 0),
        "workflow_runs_with_agent_native_estimate": data.get("workflow_runs_with_agent_native_estimate", 0),
        "workflow_runs_with_verification_evidence": data.get("workflow_runs_with_verification_evidence", 0),
        "workflow_runs_with_outcome": data.get("workflow_runs_with_outcome", 0),
        "workflow_runs_with_eval_score": data.get("workflow_runs_with_eval_score", 0),
        "workflow_runs_with_failed_verification_markers": data.get("workflow_runs_with_failed_verification_markers", 0),
        "codex_run_artifacts": data.get("codex_run_artifacts", 0),
        "eval_tasks": data.get("eval_tasks", 0),
        "eval_goldens": data.get("eval_goldens", 0),
        "provider_cost": data.get("provider_cost", INSUFFICIENT),
        "provider_tokens": data.get("provider_tokens", INSUFFICIENT),
        "acu": data.get("acu", INSUFFICIENT),
        "estimate_calibration": data.get("estimate_calibration", INSUFFICIENT),
    }


def summarize_session_insights() -> dict[str, Any]:
    path = ROOT / "scripts" / "session-insights.sh"
    if not script_available(path):
        return {
            "available": False,
            "status": INSUFFICIENT,
            "path": "scripts/session-insights.sh",
            "provider_cost": INSUFFICIENT,
            "provider_tokens": INSUFFICIENT,
        }

    result, data = parse_json_command(["bash", "scripts/session-insights.sh", "--json"], timeout=30)
    if data is None:
        return {
            "available": True,
            "status": "unhealthy",
            "path": "scripts/session-insights.sh",
            "command_exit": result["exit_code"],
            "error": (result.get("json_error") or result["stderr"] or result["stdout"]).strip(),
            "provider_cost": INSUFFICIENT,
            "provider_tokens": INSUFFICIENT,
        }

    issue_counts: Counter[str] = Counter()
    for record in data.get("records", []):
        if isinstance(record, dict):
            issue_counts.update(str(issue) for issue in record.get("issues", []))

    return {
        "available": True,
        "status": data.get("status", "unknown"),
        "path": "scripts/session-insights.sh",
        "command_exit": result["exit_code"],
        "source": data.get("source", ""),
        "run_count": data.get("run_count", 0),
        "healthy_count": data.get("healthy_count", 0),
        "unhealthy_count": data.get("unhealthy_count", 0),
        "top_issues": [
            {"issue": issue, "count": count}
            for issue, count in issue_counts.most_common(8)
        ],
        "provider_cost": data.get("provider_cost", INSUFFICIENT),
        "provider_tokens": data.get("provider_tokens", INSUFFICIENT),
    }


def collect_provider_telemetry(run_metrics: dict[str, Any], session_insights: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider_cost": run_metrics.get("provider_cost")
        or session_insights.get("provider_cost")
        or INSUFFICIENT,
        "provider_tokens": run_metrics.get("provider_tokens")
        or session_insights.get("provider_tokens")
        or INSUFFICIENT,
        "acu": run_metrics.get("acu") or INSUFFICIENT,
        "estimate_calibration": run_metrics.get("estimate_calibration") or INSUFFICIENT,
    }


def assess(payload: dict[str, Any]) -> tuple[str, list[str]]:
    notes: list[str] = []
    severity = 0

    git = payload["git"]
    if not git["available"]:
        severity = max(severity, 1)
        notes.append("git_status_unavailable")
    elif git["dirty_count"]:
        severity = max(severity, 1)
        notes.append(f"git_dirty:{git['dirty_count']}")

    spec = payload["spec"]
    if not spec["present"]:
        severity = max(severity, 2)
        notes.append("spec_missing")
    elif not spec["has_agent_native_estimate"]:
        severity = max(severity, 1)
        notes.append("spec_missing_agent_native_estimate")

    claude = payload["claude_settings"]
    if not claude["present"] or not claude["valid_json"]:
        severity = max(severity, 2)
        notes.append("claude_settings_invalid_or_missing")
    elif claude["missing_referenced_hook_scripts"]:
        severity = max(severity, 2)
        notes.append("claude_hook_mapping_references_missing_scripts")
    elif not claude["hook_mappings"]:
        severity = max(severity, 1)
        notes.append("claude_hook_mappings_empty")

    memory = payload["memory"]
    if not memory["available"] or memory["status"] in {INSUFFICIENT, "unknown"}:
        severity = max(severity, 1)
        notes.append("memory_health_unavailable")
    elif memory["status"] == "disabled" or memory.get("fail_count", 0):
        severity = max(severity, 2)
        notes.append("memory_health_disabled_or_failed")
    elif memory["status"] == "degraded" or memory.get("warn_count", 0):
        severity = max(severity, 1)
        notes.append("memory_health_degraded")

    run_metrics = payload["run_metrics"]
    if not run_metrics["available"] or run_metrics["status"] != "healthy":
        severity = max(severity, 1)
        notes.append("run_metrics_unavailable_or_unhealthy")

    session = payload["session_insights"]
    if not session["available"]:
        severity = max(severity, 1)
        notes.append("session_insights_unavailable")
    elif session["status"] == "unhealthy":
        severity = max(severity, 1)
        notes.append(f"session_insights_unhealthy:{session.get('unhealthy_count', 0)}")

    for key, value in payload["provider_telemetry"].items():
        if value == INSUFFICIENT:
            notes.append(f"{key}:insufficient_data")

    return ("unhealthy" if severity >= 2 else "attention" if severity == 1 else "healthy"), notes


def render_text(payload: dict[str, Any]) -> str:
    git = payload["git"]
    spec = payload["spec"]
    claude = payload["claude_settings"]
    memory = payload["memory"]
    run_metrics = payload["run_metrics"]
    session = payload["session_insights"]
    telemetry = payload["provider_telemetry"]

    lines = [
        "Harness Doctor",
        f"root: {payload['root']}",
        f"generated_at: {payload['generated_at']}",
        f"overall_status: {payload['overall_status']}",
        "",
        f"Git: {git['status']} dirty_count={git['dirty_count']} branch={git.get('branch', '')} head={git.get('head', '')}",
    ]
    for entry in git.get("entries", [])[:12]:
        lines.append(f"  - {entry}")
    if git.get("dirty_count", 0) > 12:
        lines.append(f"  - ... {git['dirty_count'] - 12} more")

    lines.extend(
        [
            f"SPEC.md: present={str(spec['present']).lower()} agent_native_estimate={str(spec['has_agent_native_estimate']).lower()} title={spec.get('title', '')}",
            f"Claude settings: present={str(claude['present']).lower()} valid_json={str(claude['valid_json']).lower()} status={claude['status']} hook_events={','.join(claude.get('hook_events', [])) or 'none'} hook_mappings={claude.get('hook_mapping_count', 0)}",
        ]
    )
    missing_hooks = claude.get("missing_referenced_hook_scripts", [])
    if missing_hooks:
        lines.append(f"  missing_hook_scripts={','.join(missing_hooks)}")
    else:
        lines.append("  referenced_hook_scripts=ok")

    lines.extend(
        [
            f"Memory: available={str(memory['available']).lower()} status={memory['status']} pass={memory.get('pass_count', 0)} warn={memory.get('warn_count', 0)} fail={memory.get('fail_count', 0)} exit={memory.get('command_exit')}",
            "Run metrics: "
            f"available={str(run_metrics['available']).lower()} status={run_metrics['status']} "
            f"workflow_runs={run_metrics.get('workflow_runs', 0)} estimates={run_metrics.get('workflow_runs_with_agent_native_estimate', 0)} "
            f"verification={run_metrics.get('workflow_runs_with_verification_evidence', 0)} outcomes={run_metrics.get('workflow_runs_with_outcome', 0)} "
            f"eval_tasks={run_metrics.get('eval_tasks', 0)} eval_goldens={run_metrics.get('eval_goldens', 0)}",
            "Session insights: "
            f"available={str(session['available']).lower()} status={session['status']} runs={session.get('run_count', 0)} "
            f"healthy={session.get('healthy_count', 0)} unhealthy={session.get('unhealthy_count', 0)}",
        ]
    )
    if session.get("top_issues"):
        issue_text = ", ".join(f"{item['issue']}={item['count']}" for item in session["top_issues"])
        lines.append(f"  top_issues: {issue_text}")

    lines.extend(
        [
            "Provider telemetry: "
            f"cost={telemetry['provider_cost']} tokens={telemetry['provider_tokens']} "
            f"acu={telemetry['acu']} estimate_calibration={telemetry['estimate_calibration']}",
            "No-secret posture: local_files_only=true network_used=false secret_files_read=false",
            "",
            "Notes:",
        ]
    )
    for note in payload["notes"]:
        lines.append(f"  - {note}")
    return "\n".join(lines) + "\n"


def render_html(payload: dict[str, Any]) -> str:
    text = render_text(payload)
    status = html.escape(payload["overall_status"])
    rows = []
    for key in ["git", "spec", "claude_settings", "memory", "run_metrics", "session_insights", "provider_telemetry"]:
        rows.append(
            "<tr><th>{}</th><td><pre>{}</pre></td></tr>".format(
                html.escape(key),
                html.escape(json.dumps(payload[key], indent=2, sort_keys=True)),
            )
        )
    return """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Harness Doctor</title>
<style>
body { font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 2rem; color: #202124; background: #f7f8fa; }
main { max-width: 1100px; margin: 0 auto; }
h1 { margin: 0 0 0.25rem; font-size: 2rem; }
.status { display: inline-block; padding: 0.25rem 0.5rem; border-radius: 6px; background: #fff3cd; border: 1px solid #e6c76e; }
pre { white-space: pre-wrap; overflow-wrap: anywhere; margin: 0; }
table { width: 100%; border-collapse: collapse; margin-top: 1rem; background: #fff; }
th, td { text-align: left; vertical-align: top; border: 1px solid #dfe3e8; padding: 0.75rem; }
th { width: 13rem; background: #f0f3f6; }
.summary { background: #fff; border: 1px solid #dfe3e8; padding: 1rem; margin-top: 1rem; }
</style>
</head>
<body>
<main>
<h1>Harness Doctor</h1>
<div class="status">overall_status: """ + status + """</div>
<section class="summary"><pre>""" + html.escape(text) + """</pre></section>
<table>
""" + "\n".join(rows) + """
</table>
</main>
</body>
</html>
"""


payload: dict[str, Any] = {
    "schema_version": 1,
    "generated_at": dt.datetime.now().astimezone().isoformat(timespec="seconds"),
    "root": str(ROOT),
    "git": collect_git(),
    "spec": collect_spec(),
    "claude_settings": collect_claude_settings(),
    "memory": collect_memory(),
    "run_metrics": summarize_run_metrics(),
    "session_insights": summarize_session_insights(),
    "no_secret_posture": {
        "local_files_only": True,
        "network_used": False,
        "secret_files_read": False,
    },
}
payload["provider_telemetry"] = collect_provider_telemetry(
    payload["run_metrics"],
    payload["session_insights"],
)
payload["overall_status"], payload["notes"] = assess(payload)

if HTML_OUT:
    out_path = pathlib.Path(HTML_OUT)
    if not out_path.is_absolute():
        out_path = ROOT / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(render_html(payload), encoding="utf-8")

if MODE == "json":
    print(json.dumps(payload, indent=2, sort_keys=True))
else:
    print(render_text(payload), end="")
PY
