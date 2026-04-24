#!/bin/bash
# minmaxing SPEC archive CLI
# Preserves the active SPEC.md before replacement and after verified closeout.

set -euo pipefail

COMMAND="${1:-archive}"
TASK="${2:-}"
OUTCOME="${3:-}"
ROOT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if [ ! -d "$ROOT_DIR" ]; then
  ROOT_DIR="$(pwd)"
fi

cd "$ROOT_DIR"

python3 - "$COMMAND" "$TASK" "$OUTCOME" "$ROOT_DIR" <<'PY'
import datetime as dt
import hashlib
import os
import pathlib
import re
import subprocess
import sys


COMMAND = sys.argv[1]
TASK_ARG = sys.argv[2].strip()
OUTCOME_ARG = sys.argv[3].strip()
ROOT = pathlib.Path(sys.argv[4]).resolve()
SPEC = ROOT / "SPEC.md"
ARCHIVE_DIR = ROOT / ".taste" / "specs"
WORKFLOW_DIR = ROOT / ".taste" / "workflow-runs"


def run_git(args: list[str]) -> str:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    except FileNotFoundError:
        return ""
    return result.stdout.strip()


def latest_workflow_artifact() -> str:
    if not WORKFLOW_DIR.exists():
        return "none"
    paths = [p for p in WORKFLOW_DIR.glob("*-workflow.md") if p.is_file()]
    if not paths:
        return "none"
    latest = max(paths, key=lambda p: p.stat().st_mtime)
    return os.path.relpath(latest, ROOT)


def quote_yaml(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def slugify(value: str, fallback: str) -> str:
    text = value.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    text = re.sub(r"-{2,}", "-", text).strip("-")
    return (text or fallback)[:72].strip("-") or fallback


def spec_title(text: str) -> str:
    for line in text.splitlines():
        match = re.match(r"^#\s+SPEC:\s*(.+?)\s*$", line)
        if match:
            return match.group(1).strip()
    for line in text.splitlines():
        match = re.match(r"^#\s+(.+?)\s*$", line)
        if match:
            return match.group(1).strip()
    return TASK_ARG or "untitled-spec"


def existing_archive(source_hash: str) -> pathlib.Path | None:
    if not ARCHIVE_DIR.exists():
        return None
    needle = f"source_sha256: {source_hash}"
    for path in sorted(ARCHIVE_DIR.glob("*.md")):
        try:
            head = path.read_text(encoding="utf-8", errors="replace")[:1200]
        except OSError:
            continue
        if needle in head:
            return path
    return None


def archive(reason: str) -> int:
    if not SPEC.exists():
        print("SPEC archive skipped: SPEC.md missing")
        return 0

    text = SPEC.read_text(encoding="utf-8", errors="replace")
    if not text.strip():
        print("SPEC archive skipped: SPEC.md empty")
        return 0

    source_hash = hashlib.sha256(text.encode("utf-8")).hexdigest()
    existing = existing_archive(source_hash)
    if existing is not None:
        print(f"SPEC archive already exists: {os.path.relpath(existing, ROOT)}")
        return 0

    title = spec_title(text)
    default_outcome = {
        "archive": "verified",
        "closeout": "verified",
        "prepare": "superseded-before-new-spec",
    }.get(reason, reason)
    outcome = OUTCOME_ARG or default_outcome
    now = dt.datetime.now(dt.timezone.utc).astimezone()
    stamp = now.strftime("%Y%m%d-%H%M%S")
    title_slug = slugify(title, "spec")
    outcome_slug = slugify(outcome, "archived")[:48]
    destination = ARCHIVE_DIR / f"{stamp}-{title_slug}-{outcome_slug}.md"
    counter = 2
    while destination.exists():
        destination = ARCHIVE_DIR / f"{stamp}-{title_slug}-{outcome_slug}-{counter}.md"
        counter += 1

    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)

    frontmatter = "\n".join(
        [
            "---",
            f"archived_at: {now.isoformat(timespec='seconds')}",
            f"reason: {quote_yaml(reason)}",
            f"task: {quote_yaml(TASK_ARG or title)}",
            f"spec_title: {quote_yaml(title)}",
            f"outcome: {quote_yaml(outcome)}",
            "source: SPEC.md",
            f"source_sha256: {source_hash}",
            f"git_branch: {quote_yaml(run_git(['branch', '--show-current']) or 'unknown')}",
            f"git_head: {quote_yaml(run_git(['rev-parse', '--short', 'HEAD']) or 'unknown')}",
            f"workflow_artifact: {quote_yaml(latest_workflow_artifact())}",
            "---",
            "",
        ]
    )

    destination.write_text(frontmatter + text.rstrip() + "\n", encoding="utf-8")
    print(f"SPEC archived: {os.path.relpath(destination, ROOT)}")
    return 0


def status() -> int:
    if not ARCHIVE_DIR.exists():
        print("No archived specs found.")
        return 0
    paths = sorted(ARCHIVE_DIR.glob("*.md"))
    if not paths:
        print("No archived specs found.")
        return 0
    for path in paths[-20:]:
        print(os.path.relpath(path, ROOT))
    return 0


def main() -> int:
    if COMMAND in {"archive", "closeout"}:
        return archive("closeout" if COMMAND == "closeout" else "archive")
    if COMMAND == "prepare":
        return archive("prepare")
    if COMMAND == "status":
        return status()
    print(
        "Usage: spec-archive.sh archive|closeout|prepare|status [task] [outcome]",
        file=sys.stderr,
    )
    return 2


raise SystemExit(main())
PY
