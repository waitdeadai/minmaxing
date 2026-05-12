#!/bin/bash
# Generate and check the canonical minmaxing harness capability map.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="write"
JSON_ONLY=0

usage() {
  cat >&2 <<'EOF'
Usage:
  bash scripts/harness-capability-map.sh
  bash scripts/harness-capability-map.sh --write
  bash scripts/harness-capability-map.sh --check
  bash scripts/harness-capability-map.sh --json

Generates docs/harness-capability-map.md and docs/harness-capability-map.json
from committed harness truth surfaces.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--check")
      MODE="check"
      shift
      ;;
    "--write")
      MODE="write"
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
import difflib
import hashlib
import json
import pathlib
import re
import sys
from datetime import datetime, timezone


ROOT = pathlib.Path(sys.argv[1]).resolve()
MODE = sys.argv[2]
JSON_ONLY = sys.argv[3] == "1"
DOC_PATH = ROOT / "docs" / "harness-capability-map.md"
JSON_PATH = ROOT / "docs" / "harness-capability-map.json"

SKILL_DIR = ROOT / ".claude" / "skills"
RULE_DIR = ROOT / ".claude" / "rules"
SCRIPT_DIR = ROOT / "scripts"
TASK_DIR = ROOT / "evals" / "harness" / "tasks"
GOLDEN_DIR = ROOT / "evals" / "harness" / "golden"
SETTINGS_PATH = ROOT / ".claude" / "settings.json"
CODEX_DIR = ROOT / ".codex"
CODEX_SKILL_DIR = ROOT / ".agents" / "skills"


ROUTE_GROUPS = {
    "workflow": "execution",
    "hiveworkflow": "execution",
    "opusworkflow": "execution",
    "opusminimax": "execution",
    "sonnetminimax": "support",
    "opusolo": "support",
    "visualizeworkflow": "execution",
    "demo": "execution",
    "parallel": "parallelism",
    "sprint": "parallelism",
    "hive": "parallelism",
    "metacognition": "routing",
    "claudeproduct": "knowledge",
    "digestaste": "kernel",
    "deepretaste": "kernel",
    "defineicp": "research",
    "icpweek": "research",
    "deepresearch": "research",
    "webresearch": "research",
    "browse": "research",
    "digestflow": "research",
    "audit": "quality",
    "review": "quality",
    "qa": "quality",
    "specqa": "quality",
    "verify": "quality",
    "introspect": "quality",
    "agentfactory": "agent-systems",
    "tastebootstrap": "kernel",
    "align": "kernel",
    "autoplan": "planning",
    "investigate": "debugging",
    "codesearch": "debugging",
    "ship": "release",
    "memory": "memory",
    "overnight": "operations",
    "remote-control": "operations",
    "agent-view": "operations",
    "goal-mode": "operations",
    "council": "planning",
    "visualize": "design",
}

CORE_ROUTES = {
    "workflow",
    "metacognition",
    "claudeproduct",
    "deepresearch",
    "digestaste",
    "deepretaste",
    "opusworkflow",
    "opusminimax",
    "sonnetminimax",
    "opusolo",
    "webresearch",
    "parallel",
    "hive",
    "hiveworkflow",
    "introspect",
    "verify",
    "agentfactory",
    "demo",
    "remote-control",
    "agent-view",
    "goal-mode",
    "specqa",
}

REQUIRED_COMMANDS = {
    "release-check": "public release/static gate",
    "test-harness": "full local harness regression suite",
    "harness-eval": "static eval pack runner",
    "harness-capability-map": "capability map freshness gate",
    "demo-smoke": "recorded demo contract and manifest gate",
    "defineicp-smoke": "ICP-to-taste evolution contract gate",
    "digestaste-smoke": "research-to-taste bootstrap text contract gate",
    "deepretaste-smoke": "intent-to-ICP-to-taste bootstrap contract gate",
    "claudeproduct-scorecard": "Claude product answer scorecard",
    "metacognition-scorecard": "metacognition scorecard",
    "hive-scorecard": "hive coordination scorecard",
    "hive-aggregate": "hive run aggregate validator",
    "artifact-lint": "machine sidecar validator",
    "opusminimax-benchmark-smoke": "OpusMiniMax benchmark honesty gate",
    "opusminimax-doctor": "OpusMiniMax provider split doctor",
    "opusworkflow-smoke": "OpusWorkflow cost-optimized route gate",
    "sonnetminimaxworkflow": "power-user Sonnet plus MiniMax Token Plan workflow wrapper",
    "opusoloworkflow": "optional all-Opus workflow wrapper",
    "opussonnetworkflow": "optional Claude-only Opus plus Sonnet workflow wrapper",
    "remote-control-smoke": "native Claude Code Remote Control compatibility gate",
    "agent-view-smoke": "native Claude Code Agent View static readiness gate",
    "goal-mode-smoke": "native Claude Code /goal static readiness gate",
    "specqa-smoke": "automated SOTA Spec QA gate",
    "parallel-capacity": "local parallel capacity profile",
    "parallel-aggregate": "parallel worker aggregate validator",
    "parallel-plan-lint": "parallel plan fixture lint",
    "hook-smoke": "Claude Code hook enforcement smoke",
}

RULE_OWNERS = {
    "claudeproduct": ["claudeproduct"],
    "metacognition": ["metacognition"],
    "hive": ["hive", "hiveworkflow"],
    "visualization": ["visualize", "visualizeworkflow"],
    "parallelism": ["parallel", "sprint", "hive", "hiveworkflow"],
    "memory": ["memory"],
    "estimation": ["workflow", "autoplan", "parallel", "sprint"],
    "verify": ["verify", "workflow", "specqa"],
    "spec": ["workflow", "autoplan", "ship", "specqa"],
    "security": ["workflow", "ship", "agentfactory"],
}

SCRIPT_OWNERS = {
    "claudeproduct-scorecard": ["claudeproduct"],
    "metacognition-scorecard": ["metacognition"],
    "hive-scorecard": ["hive", "hiveworkflow"],
    "hive-aggregate": ["hive", "hiveworkflow"],
    "visualize-smoke": ["visualize", "visualizeworkflow"],
    "agentfactory-smoke": ["agentfactory"],
    "demo-smoke": ["demo"],
    "defineicp-smoke": ["defineicp"],
    "digestaste-smoke": ["digestaste"],
    "deepretaste-smoke": ["deepretaste"],
    "parallel-smoke": ["parallel"],
    "parallel-capacity": ["parallel", "metacognition", "workflow"],
    "parallel-plan-lint": ["parallel"],
    "parallel-aggregate": ["parallel"],
    "estimate-smoke": ["workflow", "autoplan"],
    "artifact-lint": ["parallel", "hive", "workflow"],
    "minimax-exec": ["opusminimax", "opusworkflow"],
    "opusminimax": ["opusminimax"],
    "opusminimax-benchmark-smoke": ["opusminimax"],
    "opusminimax-doctor": ["opusminimax", "opusworkflow"],
    "opusworkflow": ["opusworkflow"],
    "opusworkflow-smoke": ["opusworkflow"],
    "sonnetminimaxworkflow": ["sonnetminimax", "opusworkflow"],
    "opusoloworkflow": ["opusolo", "opusworkflow"],
    "opussonnetworkflow": ["opussonnet", "opusworkflow"],
    "remote-control-doctor": ["remote-control"],
    "remote-control-smoke": ["remote-control"],
    "agent-view-doctor": ["agent-view"],
    "agent-view-smoke": ["agent-view"],
    "goal-mode-doctor": ["goal-mode"],
    "goal-mode-smoke": ["goal-mode"],
    "specqa-smoke": ["specqa", "workflow", "opusworkflow", "digestflow", "verify"],
    "harness-eval": ["workflow"],
    "release-check": ["ship", "workflow"],
    "test-harness": ["workflow"],
    "harness-capability-map": ["claudeproduct", "workflow"],
}


def rel(path: pathlib.Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def parse_frontmatter(path: pathlib.Path) -> tuple[dict[str, str], str]:
    text = path.read_text(encoding="utf-8")
    meta: dict[str, str] = {}
    body = text
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            raw = text[4:end].splitlines()
            body = text[end + 5 :]
            for line in raw:
                if ":" not in line or line.lstrip().startswith("#"):
                    continue
                key, value = line.split(":", 1)
                meta[key.strip()] = value.strip().strip('"').strip("'")
    return meta, body


def first_heading(body: str) -> str:
    for line in body.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return ""


def sentence(text: str, fallback: str) -> str:
    text = " ".join(text.strip().split())
    return text or fallback


def parse_task_yaml(path: pathlib.Path) -> dict[str, str]:
    data: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip().strip('"').strip("'")
    return data


def script_purpose(path: pathlib.Path) -> str:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    for line in lines[:8]:
        stripped = line.strip()
        if stripped.startswith("#!") or not stripped:
            continue
        if stripped.startswith("#"):
            return sentence(stripped.lstrip("#").strip(), "script")
    return "script"


def collect_skills() -> list[dict[str, object]]:
    skills: list[dict[str, object]] = []
    for path in sorted(SKILL_DIR.glob("*/SKILL.md")):
        meta, body = parse_frontmatter(path)
        name = meta.get("name") or path.parent.name
        description = meta.get("description") or first_heading(body) or name
        text = path.read_text(encoding="utf-8")
        related_rules = [
            rel(RULE_DIR / f"{rule}.rules.md")
            for rule, owners in RULE_OWNERS.items()
            if name in owners and (RULE_DIR / f"{rule}.rules.md").exists()
        ]
        related_scripts = [
            rel(SCRIPT_DIR / f"{script}.sh")
            for script, owners in SCRIPT_OWNERS.items()
            if name in owners and (SCRIPT_DIR / f"{script}.sh").exists()
        ]
        related_evals = [
            rel(path)
            for path in sorted(TASK_DIR.glob("*.yaml"))
            if name in path.stem
        ]
        skills.append(
            {
                "name": name,
                "slash": f"/{name}",
                "path": rel(path),
                "group": ROUTE_GROUPS.get(name, "support"),
                "description": sentence(description, name),
                "user_invocable": True,
                "model_invocation": not (meta.get("disable-model-invocation", "").lower() == "true"),
                "argument_hint": meta.get("argument-hint", ""),
                "line_count": len(text.splitlines()),
                "sha256": sha256_text(text),
                "core_route": name in CORE_ROUTES,
                "related_rules": related_rules,
                "related_scripts": related_scripts,
                "related_eval_tasks": related_evals,
            }
        )
    return skills


def collect_rules() -> list[dict[str, object]]:
    rules: list[dict[str, object]] = []
    for path in sorted(RULE_DIR.glob("*.rules.md")):
        text = path.read_text(encoding="utf-8")
        title = first_heading(text) or path.name.replace(".rules.md", "")
        rules.append(
            {
                "name": path.name.replace(".rules.md", ""),
                "path": rel(path),
                "title": title,
                "line_count": len(text.splitlines()),
                "sha256": sha256_text(text),
            }
        )
    return rules


def collect_scripts() -> list[dict[str, object]]:
    scripts: list[dict[str, object]] = []
    for path in sorted(SCRIPT_DIR.glob("*.sh")):
        text = path.read_text(encoding="utf-8", errors="replace")
        stem = path.stem
        scripts.append(
            {
                "name": stem,
                "path": rel(path),
                "purpose": REQUIRED_COMMANDS.get(stem, script_purpose(path)),
                "required_gate": stem in REQUIRED_COMMANDS,
                "line_count": len(text.splitlines()),
                "sha256": sha256_text(text),
            }
        )
    return scripts


def collect_evals() -> list[dict[str, str]]:
    evals: list[dict[str, str]] = []
    for path in sorted(TASK_DIR.glob("*.yaml")):
        data = parse_task_yaml(path)
        golden = data.get("golden", "")
        evals.append(
            {
                "id": data.get("id", path.stem),
                "title": data.get("title", path.stem),
                "gate": data.get("gate", ""),
                "expected_result": data.get("expected_result", ""),
                "task_path": rel(path),
                "golden_path": golden,
                "golden_exists": str((ROOT / golden).exists()).lower() if golden else "false",
            }
        )
    return evals


def collect_settings() -> dict[str, object]:
    if not SETTINGS_PATH.exists():
        return {"path": rel(SETTINGS_PATH), "exists": False, "hooks": [], "permissions": {}}
    data = json.loads(SETTINGS_PATH.read_text(encoding="utf-8"))
    hooks: list[dict[str, object]] = []
    for event, entries in sorted((data.get("hooks") or {}).items()):
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            commands = []
            for hook in entry.get("hooks") or []:
                if isinstance(hook, dict):
                    commands.append(
                        {
                            "type": hook.get("type", ""),
                            "command": hook.get("command", ""),
                            "timeout": hook.get("timeout", ""),
                        }
                    )
            hooks.append(
                {
                    "event": event,
                    "matcher": entry.get("matcher", ""),
                    "commands": commands,
                }
            )
    permissions = data.get("permissions") or {}
    return {
        "path": rel(SETTINGS_PATH),
        "exists": True,
        "env_keys": sorted((data.get("env") or {}).keys()),
        "permissions": {
            "allow": permissions.get("allow", []),
            "deny": permissions.get("deny", []),
            "defaultMode": permissions.get("defaultMode", ""),
        },
        "hooks": hooks,
        "secret_values_redacted": True,
    }


def collect_codex() -> dict[str, object]:
    files = []
    for path in sorted(CODEX_DIR.glob("**/*")):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        names = re.findall(r'^name\s*=\s*"([^"]+)"', text, flags=re.MULTILINE)
        descriptions = re.findall(r'^description\s*=\s*"([^"]+)"', text, flags=re.MULTILINE)
        max_threads = re.findall(r'^max_threads\s*=\s*([0-9]+)', text, flags=re.MULTILINE)
        mcp_servers = re.findall(r'^\[mcp_servers\.([^\]]+)\]', text, flags=re.MULTILINE)
        files.append(
            {
                "path": rel(path),
                "names": names,
                "descriptions": descriptions,
                "max_threads": max_threads[0] if max_threads else "",
                "mcp_servers": sorted(set(mcp_servers)),
                "sha256": sha256_text(text),
            }
        )
    return {"path": rel(CODEX_DIR), "files": files}


def collect_codex_skills() -> list[dict[str, object]]:
    skills: list[dict[str, object]] = []
    if not CODEX_SKILL_DIR.exists():
        return skills
    for path in sorted(CODEX_SKILL_DIR.glob("*/SKILL.md")):
        meta, body = parse_frontmatter(path)
        name = meta.get("name") or path.parent.name
        description = meta.get("description") or first_heading(body) or name
        text = path.read_text(encoding="utf-8")
        agents_yaml = path.parent / "agents" / "openai.yaml"
        skills.append(
            {
                "name": name,
                "path": rel(path),
                "description": sentence(description, name),
                "line_count": len(text.splitlines()),
                "sha256": sha256_text(text),
                "agents_metadata": rel(agents_yaml) if agents_yaml.exists() else "",
            }
        )
    return skills


def build_map() -> dict[str, object]:
    skills = collect_skills()
    codex_skills = collect_codex_skills()
    rules = collect_rules()
    scripts = collect_scripts()
    evals = collect_evals()
    settings = collect_settings()
    codex = collect_codex()
    groups: dict[str, list[str]] = {}
    for skill in skills:
        groups.setdefault(str(skill["group"]), []).append(str(skill["slash"]))
    return {
        "artifact_type": "harness-capability-map",
        "schema_version": "minmaxing-harness-capabilities/v1",
        "generated_by": "scripts/harness-capability-map.sh",
        "generated_at": "static",
        "source_policy": {
            "local_truth": [
                ".claude/skills/*/SKILL.md",
                ".claude/rules/*.rules.md",
                "scripts/*.sh",
                "evals/harness/tasks/*.yaml",
                "evals/harness/golden/*.json",
                ".claude/settings.json",
                ".claude/hooks/*",
                ".codex/**/*.toml",
                ".agents/skills/*/SKILL.md",
                "README.md",
                "CLAUDE.md",
                "AGENTS.md",
            ],
            "secret_policy": "does not read .env, .env.*, settings.local.json, private/customer artifacts, or runtime secrets",
        },
        "summary": {
            "skill_count": len(skills),
            "rule_count": len(rules),
            "script_count": len(scripts),
            "eval_task_count": len(evals),
            "hook_event_count": len(settings.get("hooks", [])) if isinstance(settings, dict) else 0,
            "codex_file_count": len(codex.get("files", [])) if isinstance(codex, dict) else 0,
            "codex_skill_count": len(codex_skills),
            "core_route_count": sum(1 for skill in skills if skill["core_route"]),
            "groups": {key: sorted(value) for key, value in sorted(groups.items())},
        },
        "counts": {
            "skills": len(skills),
            "codex_skills": len(codex_skills),
            "rules": len(rules),
            "scripts": len(scripts),
            "eval_tasks": len(evals),
        },
        "skills": skills,
        "codex_skills": codex_skills,
        "rules": rules,
        "scripts": scripts,
        "evals": evals,
        "settings": settings,
        "codex": codex,
        "self_lookup_contract": {
            "primary_human_map": rel(DOC_PATH),
            "primary_machine_map": rel(JSON_PATH),
            "fallback_surfaces": [
                ".claude/skills/",
                ".claude/rules/",
                ".claude/settings.json",
                ".claude/hooks/",
                ".codex/",
                ".agents/skills/",
                "CLAUDE.md",
                "AGENTS.md",
                "README.md",
                "scripts/start-session.sh",
            ],
            "verification_command": "bash scripts/harness-capability-map.sh --check",
        },
    }


def markdown(payload: dict[str, object]) -> str:
    summary = payload["summary"]  # type: ignore[index]
    skills = payload["skills"]  # type: ignore[index]
    codex_skills = payload["codex_skills"]  # type: ignore[index]
    rules = payload["rules"]  # type: ignore[index]
    scripts = payload["scripts"]  # type: ignore[index]
    evals = payload["evals"]  # type: ignore[index]
    settings = payload["settings"]  # type: ignore[index]
    codex = payload["codex"]  # type: ignore[index]
    groups = summary["groups"]  # type: ignore[index]
    lines: list[str] = [
        "# Harness Capability Map",
        "",
        "> Generated by `bash scripts/harness-capability-map.sh`. Do not edit by hand.",
        "",
        "This is the canonical local map for minmaxing self-lookup. Use it when",
        "`/claudeproduct` or an operator asks what the harness can do, which route to",
        "choose, which scripts prove a claim, or where the detailed contract lives.",
        "",
        "## Summary",
        "",
        f"- Skills: {summary['skill_count']}",
        f"- Rules: {summary['rule_count']}",
        f"- Scripts: {summary['script_count']}",
        f"- Static eval tasks: {summary['eval_task_count']}",
        f"- Hook entries: {summary['hook_event_count']}",
        f"- Codex config files: {summary['codex_file_count']}",
        f"- Codex repo skills: {summary['codex_skill_count']}",
        f"- Core routes: {summary['core_route_count']}",
        "- Secret policy: generated from committed repo truth only; never reads `.env`,",
        "  `.env.*`, `.claude/settings.local.json`, private customer artifacts, or",
        "  runtime secrets.",
        "",
        "## Route Groups",
        "",
    ]
    for group, names in groups.items():  # type: ignore[union-attr]
        lines.append(f"- `{group}`: {', '.join(f'`{name}`' for name in names)}")
    lines += [
        "",
        "## Skills",
        "",
        "| Skill | Group | Model Auto-Invocation | Core Route | Contract | Description |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for skill in skills:  # type: ignore[union-attr]
        auto = "yes" if skill["model_invocation"] else "manual"
        core = "yes" if skill["core_route"] else "no"
        desc = str(skill["description"]).replace("|", "\\|")
        lines.append(
            f"| `{skill['slash']}` | `{skill['group']}` | {auto} | {core} | `{skill['path']}` | {desc} |"
        )
    lines += [
        "",
        "## Codex Repo Skills",
        "",
        "| Skill | Contract | Agents Metadata | Description |",
        "| --- | --- | --- | --- |",
    ]
    if codex_skills:  # type: ignore[truthy-function]
        for skill in codex_skills:  # type: ignore[union-attr]
            desc = str(skill["description"]).replace("|", "\\|")
            metadata = str(skill.get("agents_metadata", ""))
            lines.append(
                f"| `{skill['name']}` | `{skill['path']}` | `{metadata}` | {desc} |"
            )
    else:
        lines.append("| `none` | `` | `` | No repo-scoped Codex skills found. |")
    lines += [
        "",
        "## Rules",
        "",
        "| Rule | Contract | Lines |",
        "| --- | --- | --- |",
    ]
    for rule in rules:  # type: ignore[union-attr]
        lines.append(f"| `{rule['name']}` | `{rule['path']}` | {rule['line_count']} |")
    lines += [
        "",
        "## Required Script Gates",
        "",
        "| Script | Purpose | Path |",
        "| --- | --- | --- |",
    ]
    for script in scripts:  # type: ignore[union-attr]
        if not script["required_gate"]:
            continue
        purpose = str(script["purpose"]).replace("|", "\\|")
        lines.append(f"| `{script['name']}` | {purpose} | `{script['path']}` |")
    lines += [
        "",
        "## Static Eval Gates",
        "",
        "| Eval | Gate | Expected | Task | Golden |",
        "| --- | --- | --- | --- | --- |",
    ]
    for item in evals:  # type: ignore[union-attr]
        lines.append(
            f"| `{item['id']}` | `{item['gate']}` | `{item['expected_result']}` | `{item['task_path']}` | `{item['golden_path']}` |"
        )
    lines += [
        "",
        "## Claude Code Settings And Hooks",
        "",
        f"- Settings path: `{settings['path']}`",
        f"- Secret values redacted: `{str(settings.get('secret_values_redacted', False)).lower()}`",
        f"- Default permission mode: `{settings.get('permissions', {}).get('defaultMode', '')}`",
        f"- Deny rules: {', '.join(f'`{item}`' for item in settings.get('permissions', {}).get('deny', []))}",
        "",
        "| Event | Matcher | Commands |",
        "| --- | --- | --- |",
    ]
    for hook in settings.get("hooks", []):  # type: ignore[union-attr]
        commands = "<br>".join(f"`{cmd.get('command', '')}`" for cmd in hook.get("commands", []))
        lines.append(f"| `{hook.get('event', '')}` | `{hook.get('matcher', '')}` | {commands} |")
    lines += [
        "",
        "## Codex Surfaces",
        "",
        "| File | Names | MCP Servers | Max Threads |",
        "| --- | --- | --- | --- |",
    ]
    for item in codex.get("files", []):  # type: ignore[union-attr]
        lines.append(
            f"| `{item['path']}` | {', '.join(f'`{name}`' for name in item.get('names', []))} | {', '.join(f'`{name}`' for name in item.get('mcp_servers', []))} | `{item.get('max_threads', '')}` |"
        )
    lines += [
        "",
        "## Self-Lookup Contract",
        "",
        "- For harness capability questions, cite this file first.",
        "- For machine checks or exact counts, cite `docs/harness-capability-map.json`.",
        "- If this file and repo truth disagree, regenerate with:",
        "",
        "```bash",
        "bash scripts/harness-capability-map.sh",
        "bash scripts/harness-capability-map.sh --check",
        "```",
        "",
        "- For external Claude product behavior, still use `/claudeproduct` with current",
        "  official Anthropic/Claude docs. This map describes minmaxing, not Anthropic",
        "  product truth.",
        "",
    ]
    return "\n".join(lines)


def normalized_json(payload: dict[str, object]) -> str:
    return json.dumps(payload, indent=2, sort_keys=True) + "\n"


def check_file(path: pathlib.Path, expected: str) -> bool:
    if not path.exists():
        print(f"[harness-capability-map] missing generated file: {rel(path)}", file=sys.stderr)
        return False
    current = path.read_text(encoding="utf-8")
    if current == expected:
        return True
    print(f"[harness-capability-map] stale generated file: {rel(path)}", file=sys.stderr)
    diff = difflib.unified_diff(
        current.splitlines(),
        expected.splitlines(),
        fromfile=f"{rel(path)} (current)",
        tofile=f"{rel(path)} (generated)",
        lineterm="",
    )
    for line in list(diff)[:120]:
        print(line, file=sys.stderr)
    return False


def main() -> int:
    payload = build_map()
    json_text = normalized_json(payload)
    md_text = markdown(payload)
    if MODE == "check":
        ok = check_file(DOC_PATH, md_text) and check_file(JSON_PATH, json_text)
        if JSON_ONLY:
            print(json_text, end="")
        if ok:
            if not JSON_ONLY:
                print("[PASS] harness capability map is fresh")
            return 0
        return 1
    if JSON_ONLY:
        print(json_text, end="")
        return 0
    DOC_PATH.parent.mkdir(parents=True, exist_ok=True)
    DOC_PATH.write_text(md_text, encoding="utf-8")
    JSON_PATH.write_text(json_text, encoding="utf-8")
    print(f"[PASS] wrote {rel(DOC_PATH)} and {rel(JSON_PATH)}")
    return 0


raise SystemExit(main())
PY
