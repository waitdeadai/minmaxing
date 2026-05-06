#!/bin/bash
# Static and opt-in runtime checks for the Opus planner + MiniMax executor split.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="static"
JSON_ONLY=0

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/opusminimax-doctor.sh --static [--json]
  bash scripts/opusminimax-doctor.sh --runtime [--json]

--static is no-secret and does not run provider model calls.
--runtime may inspect local Claude auth/version state, but still never prints secrets.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--static")
      MODE="static"
      shift
      ;;
    "--runtime")
      MODE="runtime"
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
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path(sys.argv[1]).resolve()
MODE = sys.argv[2]
JSON_ONLY = sys.argv[3] == "1"

PROJECT = ROOT / ".claude" / "settings.json"
PLANNER = ROOT / ".claude" / "settings.opusminimax-planner.example.json"
EXECUTOR = ROOT / ".claude" / "settings.minimax-executor.example.json"
SKILL = ROOT / ".claude" / "skills" / "opusminimax" / "SKILL.md"

SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9_-]{16,}"),
    re.compile(r"(?i)(api[_-]?key|auth[_-]?token|secret)[\"']?\s*[:=]\s*[\"'][^\"']{12,}[\"']"),
]


def rel(path: pathlib.Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def load_json(path: pathlib.Path, checks: list[dict[str, Any]]) -> dict[str, Any]:
    if not path.is_file():
        checks.append({"name": f"{rel(path)} exists", "status": "fail"})
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        checks.append({"name": f"{rel(path)} valid JSON", "status": "fail", "detail": str(exc)})
        return {}
    checks.append({"name": f"{rel(path)} valid JSON", "status": "pass"})
    return data if isinstance(data, dict) else {}


def has_hook(data: dict[str, Any], hook_name: str) -> bool:
    hooks = data.get("hooks")
    return isinstance(hooks, dict) and hook_name in hooks


def env(data: dict[str, Any]) -> dict[str, str]:
    raw = data.get("env")
    if not isinstance(raw, dict):
        return {}
    return {str(k): str(v) for k, v in raw.items()}


def add(checks: list[dict[str, Any]], name: str, ok: bool, detail: str = "") -> None:
    item = {"name": name, "status": "pass" if ok else "fail"}
    if detail:
        item["detail"] = detail
    checks.append(item)


def git_files() -> list[pathlib.Path]:
    try:
        result = subprocess.run(
            ["git", "ls-files"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except FileNotFoundError:
        return []
    return [ROOT / line for line in result.stdout.splitlines() if line.strip()]


def tracked_secret_findings() -> list[str]:
    findings: list[str] = []
    skip_names = {".claude/settings.local.json"}
    for path in git_files():
        rel_path = rel(path)
        if path.name in skip_names or ".local.json" in rel_path:
            continue
        rel_path = rel(path)
        if rel_path.startswith(".taste/fixtures/"):
            continue
        if any(part in {".git", ".venv", ".deps"} for part in path.parts):
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                if "YOUR_MINIMAX_API_KEY" in text and pattern.pattern.lower().find("api") >= 0:
                    continue
                findings.append(rel_path)
                break
    return sorted(set(findings))


def claude_version_status() -> dict[str, Any]:
    try:
        result = subprocess.run(
            ["claude", "--version"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=10,
        )
    except Exception as exc:
        return {"status": "warn", "detail": f"claude unavailable: {exc}"}
    text = (result.stdout or result.stderr).strip()
    match = re.search(r"(\d+)\.(\d+)\.(\d+)", text)
    if not match:
        return {"status": "warn", "detail": text or "unknown version"}
    version = tuple(map(int, match.groups()))
    ok = version >= (2, 1, 111)
    return {"status": "pass" if ok else "fail", "detail": text}


def claude_auth_status() -> dict[str, Any]:
    try:
        result = subprocess.run(
            ["claude", "auth", "status", "--text"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=15,
        )
    except Exception as exc:
        return {"status": "warn", "detail": f"auth probe unavailable: {exc}"}
    text = (result.stdout or result.stderr).strip()
    return {"status": "pass" if result.returncode == 0 else "warn", "detail": text}


checks: list[dict[str, Any]] = []
project = load_json(PROJECT, checks)
planner = load_json(PLANNER, checks)
executor = load_json(EXECUTOR, checks)

project_env = env(project)
planner_env = env(planner)
executor_env = env(executor)

add(checks, "opusminimax skill exists", SKILL.is_file())
add(checks, "shared settings are provider-neutral", "ANTHROPIC_BASE_URL" not in project_env and "MiniMax-M2.7-highspeed" not in json.dumps(project_env, sort_keys=True))
add(checks, "shared settings keep governance hooks", has_hook(project, "PreToolUse") and has_hook(project, "Stop") and has_hook(project, "SubagentStop"))
add(checks, "shared settings deny secret reads", all(item in project.get("permissions", {}).get("deny", []) for item in ["Read(./.env)", "Read(./.env.*)", "Read(./.claude/*.local.json)", "Read(./secrets/**)"]))
add(checks, "planner profile has Opus request", planner_env.get("ANTHROPIC_DEFAULT_OPUS_MODEL", "").startswith("claude-opus-4-7") or planner_env.get("ANTHROPIC_MODEL", "").startswith("claude-opus-4-7"))
add(checks, "planner profile has no MiniMax base URL", "ANTHROPIC_BASE_URL" not in planner_env and "minimax" not in json.dumps(planner_env, sort_keys=True).lower())
add(checks, "executor profile uses MiniMax base URL", executor_env.get("ANTHROPIC_BASE_URL") == "https://api.minimax.io/anthropic")
add(checks, "executor profile uses MiniMax-M2.7-highspeed", "MiniMax-M2.7-highspeed" in json.dumps(executor_env, sort_keys=True))
add(checks, "executor profile does not alias Opus to MiniMax", executor_env.get("ANTHROPIC_DEFAULT_OPUS_MODEL", "") != "MiniMax-M2.7-highspeed")
gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8", errors="replace") if (ROOT / ".gitignore").exists() else ""
add(checks, "local profile files are ignored", ".claude/*.local.json" in gitignore)
add(checks, "opusminimax run artifacts are ignored", ".taste/opusminimax/" in gitignore)

secret_findings = tracked_secret_findings()
if secret_findings:
    checks.append(
        {
            "name": "tracked files obvious-secret scan",
            "status": "warn",
            "detail": "candidate test/fixture strings found: " + ", ".join(secret_findings[:5]),
        }
    )
else:
    add(checks, "tracked files obvious-secret scan", True)

if os.environ.get("ANTHROPIC_API_KEY"):
    checks.append(
        {
            "name": "ANTHROPIC_API_KEY subscription billing footgun",
            "status": "warn",
            "detail": "present in current environment; Claude subscription planner mode should unset it",
        }
    )

if MODE == "runtime":
    checks.append({"name": "claude version >= 2.1.111", **claude_version_status()})
    checks.append({"name": "claude auth status", **claude_auth_status()})

status = "pass"
if any(item["status"] == "fail" for item in checks):
    status = "fail"
elif any(item["status"] == "warn" for item in checks):
    status = "warn"

payload = {
    "artifact_type": "opusminimax-doctor-result",
    "mode": MODE,
    "status": status,
    "checks": checks,
    "runtime_model_calls": False,
    "secret_policy": "does not read .env, .env.*, .claude/*.local.json, or key files",
}

if JSON_ONLY:
    print(json.dumps(payload, indent=2, sort_keys=True))
else:
    for item in checks:
        detail = f" - {item['detail']}" if item.get("detail") else ""
        print(f"[{item['status'].upper()}] {item['name']}{detail}")
    print(f"[opusminimax-doctor] status={status} mode={MODE} runtime_model_calls=false")

raise SystemExit(1 if status == "fail" else 0)
PY
