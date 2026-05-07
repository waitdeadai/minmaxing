#!/bin/bash
# minmaxing - One-Command Setup
# Default mode is opusworkflow: Claude/Opus judgment + MiniMax execution.
# Suggested Claude-only mode:
# curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --mode opussonnet
# Clean/new folder:
# curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --minimax-key 'YOUR_TOKEN_PLAN_KEY'
# Existing project / updater:
# curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --minimax-key 'YOUR_TOKEN_PLAN_KEY'

set -e

MINMAXING_REPO_URL="${MINMAXING_REPO_URL:-https://github.com/waitdeadai/minmaxing.git}"
MODE="opusworkflow"
SPLIT_EXECUTION_MODE=0
EXECUTOR_PROVIDER="minimax"
API_KEY="${MINIMAX_TOKEN_KEY:-${TOKEN_KEY:-}}"
MINIMAX_KEY_FILE=""
PROMPT_MINIMAX_KEY=0
IMPORT_EXISTING=0
PLANNER_MODEL="claude-opus-4-7"
EXECUTOR_MODEL=""
PROFILE="solo-fast"
PREEXISTING_TASTE_MD=0
PREEXISTING_TASTE_VISION=0
COPIED_TEMPLATE_REPO=0
TASTE_MD_BACKUP=""
TASTE_VISION_BACKUP=""

if [ "$#" -eq 1 ] && [[ "${1:-}" != -* ]]; then
    API_KEY="$1"
else
    while [ "$#" -gt 0 ]; do
        case "$1" in
            "--mode")
                MODE="${2:-}"
                shift 2
                ;;
            "--minimax-key")
                API_KEY="${2:-}"
                shift 2
                ;;
            "--minimax-key-file")
                MINIMAX_KEY_FILE="${2:-}"
                shift 2
                ;;
            "--prompt-minimax-key")
                PROMPT_MINIMAX_KEY=1
                shift
                ;;
            "--import-existing")
                IMPORT_EXISTING=1
                shift
                ;;
            "--planner-model")
                PLANNER_MODEL="${2:-}"
                shift 2
                ;;
            "--executor-model")
                EXECUTOR_MODEL="${2:-}"
                shift 2
                ;;
            "--profile")
                PROFILE="${2:-}"
                shift 2
                ;;
            "-h"|"--help")
                cat <<'EOF'
Clean/new folder:
  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --minimax-key 'YOUR_TOKEN_PLAN_KEY'

Existing project / updater:
  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --minimax-key 'YOUR_TOKEN_PLAN_KEY'

Suggested Claude-only Opus + Sonnet:
  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --mode opussonnet

After setup finishes, run: claude

Options:
  --mode minimax|opusworkflow|opusminimax|opussonnet  (default: opusworkflow)
  --import-existing
  --minimax-key KEY
  --minimax-key-file PATH
  --prompt-minimax-key
  --planner-model MODEL
  --executor-model MODEL
  --profile solo-fast|team-safe
EOF
                exit 0
                ;;
            *)
                echo "Unknown setup option: $1" >&2
                exit 2
                ;;
        esac
    done
fi

case "$MODE" in
    "minimax"|"opusminimax"|"opusworkflow"|"opussonnet") ;;
    *)
        echo "Unsupported --mode: $MODE" >&2
        exit 2
        ;;
esac

case "$MODE" in
    "opusminimax"|"opusworkflow") SPLIT_EXECUTION_MODE=1 ;;
    "opussonnet")
        SPLIT_EXECUTION_MODE=1
        EXECUTOR_PROVIDER="claude-sonnet"
        ;;
esac

if [ -z "$EXECUTOR_MODEL" ]; then
    if [ "$EXECUTOR_PROVIDER" = "claude-sonnet" ]; then
        EXECUTOR_MODEL="claude-sonnet-4-6"
    else
        EXECUTOR_MODEL="MiniMax-M2.7-highspeed"
    fi
fi

case "$PROFILE" in
    "solo-fast"|"team-safe") ;;
    *)
        echo "Unsupported --profile: $PROFILE" >&2
        exit 2
        ;;
esac

if [ -n "$MINIMAX_KEY_FILE" ]; then
    if [ ! -f "$MINIMAX_KEY_FILE" ]; then
        echo "MiniMax key file not found: $MINIMAX_KEY_FILE" >&2
        exit 2
    fi
    API_KEY="$(tr -d '\r\n' < "$MINIMAX_KEY_FILE")"
fi

prompt_for_minimax_key() {
    [ -z "$API_KEY" ] || return 0
    [ "$EXECUTOR_PROVIDER" = "minimax" ] || return 0
    [ "$PROMPT_MINIMAX_KEY" -eq 1 ] || [ "$SPLIT_EXECUTION_MODE" -eq 1 ] || return 0
    [ -t 1 ] || return 0
    [ -r /dev/tty ] || return 0

    echo "MiniMax Token Plan key not provided." > /dev/tty
    echo "Paste it now to configure the local ignored MiniMax executor profile." > /dev/tty
    printf "MiniMax token (input hidden, leave blank to skip): " > /dev/tty
    IFS= read -r -s API_KEY < /dev/tty || API_KEY=""
    printf "\n" > /dev/tty
}

prompt_for_minimax_key

dir_is_empty() {
    [ -z "$(find . -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]
}

has_minmaxing_harness() {
    [ -f ".claude/skills/workflow/SKILL.md" ] && [ -f "scripts/test-harness.sh" ]
}

append_minmaxing_gitignore_block() {
    touch .gitignore
    if ! grep -Fq "# minmaxing local state and secrets" .gitignore 2>/dev/null; then
        cat >> .gitignore <<'EOF'

# minmaxing local state and secrets
.claude/settings.local.json
.claude/*.local.json
.minimaxing/
memory/memory.db
memory/memory.db-*
.taste/*
!.taste/fixtures/
!.taste/fixtures/**
!.taste/codex-runs/
!.taste/codex-runs/**
.env
.env.*
EOF
    fi
}

clone_minmaxing_to_temp() {
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 "$MINMAXING_REPO_URL" "$TEMP_DIR"
}

import_or_update_harness() {
    local source_dir="$1"

    append_minmaxing_gitignore_block

    python3 - "$source_dir" <<'PY'
import hashlib
import pathlib
import shutil
import sys

source = pathlib.Path(sys.argv[1]).resolve()
target_root = pathlib.Path.cwd()
manifest_path = target_root / ".minimaxing" / "import-manifest.tsv"
manifest_path.parent.mkdir(parents=True, exist_ok=True)

allowed_roots = [
    ".claude/hooks",
    ".claude/rules",
    ".claude/skills",
    ".claude/settings.json",
    ".claude/settings.minimax-executor.example.json",
    ".claude/settings.opusminimax-planner.example.json",
    ".claude/settings.opussonnet.example.json",
    ".claude/settings.solo-fast.example.json",
    ".claude/settings.sonnet-executor.example.json",
    ".claude/settings.team-safe.example.json",
    ".codex",
    ".github/workflows/harness-runtime.yml",
    "AGENTS.md",
    "CLAUDE.md",
    "COMMERCIAL.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "NOTICE",
    "OPEN_CORE_STRATEGY.md",
    "SECURITY.md",
    "TRADEMARKS.md",
    "docs/harness-capability-map.md",
    "docs/harness-capability-map.json",
    "docs/metacognition-harness-moat-research-2026-05-03.md",
    "docs/runtime-governance-quickstart.md",
    "docs/runtime-hardening.md",
    "evals",
    "examples/dummy-harness-run",
    "memory",
    "schemas",
    "scripts",
    "setup.sh",
    "setup.ps1",
    "settings.json",
]

never = {
    ".git",
    ".gitignore",
    "README.md",
    "SPEC.md",
    "taste.md",
    "taste.vision",
}

def digest(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def iter_allowed_files():
    seen = set()
    for root in allowed_roots:
        path = source / root
        if not path.exists():
            continue
        if path.is_file():
            candidates = [path]
        else:
            candidates = sorted(p for p in path.rglob("*") if p.is_file())
        for item in candidates:
            rel = item.relative_to(source).as_posix()
            if rel in seen:
                continue
            seen.add(rel)
            parts = rel.split("/")
            if rel in never:
                continue
            if rel.endswith(".pyc") or "__pycache__" in parts:
                continue
            if len(parts) >= 2 and parts[0] == ".claude" and parts[1] == "projects":
                continue
            if len(parts) == 2 and parts[0] == ".claude" and parts[1].endswith(".local.json"):
                continue
            yield rel, item

previous = {}
if manifest_path.exists():
    for line in manifest_path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or "\t" not in line:
            continue
        rel, old_hash = line.split("\t", 1)
        previous[rel] = old_hash

next_manifest = {}
copied = updated = unchanged = skipped = 0
conflicts = []

for rel, src in iter_allowed_files():
    dst = target_root / rel
    src_hash = digest(src)
    old_hash = previous.get(rel)

    if dst.exists():
        if not dst.is_file():
            skipped += 1
            conflicts.append(rel)
            continue
        dst_hash = digest(dst)
        if dst_hash == src_hash:
            unchanged += 1
            next_manifest[rel] = src_hash
            continue
        if old_hash and dst_hash == old_hash:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            updated += 1
            next_manifest[rel] = src_hash
            continue
        skipped += 1
        conflicts.append(rel)
        continue

    if dst.parent.exists() and not dst.parent.is_dir():
        skipped += 1
        conflicts.append(rel)
        continue

    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    copied += 1
    next_manifest[rel] = src_hash

for rel, old_hash in previous.items():
    if rel not in next_manifest and (target_root / rel).exists():
        next_manifest[rel] = old_hash

manifest_path.write_text(
    "".join(f"{rel}\t{hash_}\n" for rel, hash_ in sorted(next_manifest.items())),
    encoding="utf-8",
)

print(
    f"  [PASS] Harness import/update complete: copied={copied}, "
    f"updated={updated}, unchanged={unchanged}, skipped_conflicts={skipped}"
)
if conflicts:
    print("  [WARN] Existing non-minmaxing files were left untouched:")
    for rel in conflicts[:20]:
        print(f"    - {rel}")
    if len(conflicts) > 20:
        print(f"    ... {len(conflicts) - 20} more")
    print("  [INFO] Re-run after resolving conflicts; tracked imports update via .minimaxing/import-manifest.tsv")
PY
}

if [ -f "taste.md" ]; then
    PREEXISTING_TASTE_MD=1
    TASTE_MD_BACKUP=$(mktemp)
    cp "taste.md" "$TASTE_MD_BACKUP"
fi

if [ -f "taste.vision" ]; then
    PREEXISTING_TASTE_VISION=1
    TASTE_VISION_BACKUP=$(mktemp)
    cp "taste.vision" "$TASTE_VISION_BACKUP"
fi

echo "=========================================="
echo "  minmaxing Setup"
echo "=========================================="
echo "Mode: $MODE"
if [ "$MODE" = "opusworkflow" ]; then
    echo "Default route: /opusworkflow (Claude/Opus judgment + MiniMax execution)"
elif [ "$MODE" = "opussonnet" ]; then
    echo "Suggested route: /opusworkflow with Claude opusplan (Opus planning + Sonnet execution)"
fi
echo ""

# Step 0: Clone repository to temp, then move to current directory
if [ "$IMPORT_EXISTING" -eq 1 ]; then
    echo "[0/7] Importing/updating minmaxing harness into existing project..."
    clone_minmaxing_to_temp
    import_or_update_harness "$TEMP_DIR"
    rm -rf "$TEMP_DIR"
elif [ ! -d ".git" ]; then
    if ! dir_is_empty; then
        echo "[0/7] Existing non-empty folder detected."
        echo "  [FAIL] Clean install refuses to copy the template into a non-empty folder."
        echo "  Use the existing-project/updater command instead:"
        echo "  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --minimax-key 'YOUR_TOKEN_PLAN_KEY'"
        exit 2
    fi
    echo "[0/7] Cloning minmaxing repository..."
    COPIED_TEMPLATE_REPO=1
    clone_minmaxing_to_temp
    cp -r "$TEMP_DIR"/* .
    cp -r "$TEMP_DIR"/.[!.]* . 2>/dev/null || true
    rm -rf "$TEMP_DIR"

    # Fresh installs should define their own kernel via /tastebootstrap.
    # The template repo tracks its own taste files, so strip only the ones
    # introduced by this copy step and leave any user-authored files alone.
    if [ "$PREEXISTING_TASTE_MD" -eq 1 ] && [ -n "$TASTE_MD_BACKUP" ]; then
        cp "$TASTE_MD_BACKUP" "taste.md"
        rm -f "$TASTE_MD_BACKUP"
    elif [ -f "taste.md" ]; then
        rm -f "taste.md"
        echo "  [INFO] Removed bundled taste.md so /tastebootstrap can define this repo's kernel"
    fi

    if [ "$PREEXISTING_TASTE_VISION" -eq 1 ] && [ -n "$TASTE_VISION_BACKUP" ]; then
        cp "$TASTE_VISION_BACKUP" "taste.vision"
        rm -f "$TASTE_VISION_BACKUP"
    elif [ -f "taste.vision" ]; then
        rm -f "taste.vision"
        echo "  [INFO] Removed bundled taste.vision so /tastebootstrap can define this repo's kernel"
    fi
else
    if has_minmaxing_harness; then
        echo "[0/7] Using existing minmaxing harness directory"
    else
        echo "[0/7] Existing git project detected."
        echo "  [FAIL] Clean install will not import into an existing project."
        echo "  Use the existing-project/updater command instead:"
        echo "  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --minimax-key 'YOUR_TOKEN_PLAN_KEY'"
        exit 2
    fi
fi

if [ -n "$TASTE_MD_BACKUP" ] && [ -f "$TASTE_MD_BACKUP" ]; then
    rm -f "$TASTE_MD_BACKUP"
fi

if [ -n "$TASTE_VISION_BACKUP" ] && [ -f "$TASTE_VISION_BACKUP" ]; then
    rm -f "$TASTE_VISION_BACKUP"
fi
echo ""

# Step 1: Check Python 3
echo "[1/7] Checking Python 3..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo "  [PASS] Python 3 found: $PYTHON_VERSION"
else
    echo "  [FAIL] Python 3 not found. Install from https://python.org"
    exit 1
fi
echo ""

# Step 2: Check uvx
echo "[2/7] Checking uvx..."
if ! command -v uvx &> /dev/null; then
    echo "Installing uvx..."
    curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || echo "uvx install skipped"
    source ~/.bashrc 2>/dev/null || true
fi
if command -v uvx &> /dev/null; then
    echo "  [PASS] uvx installed"
else
    echo "  [WARN] uvx not installed - curl -LsSf https://astral.sh/uv/install.sh | sh"
fi
echo ""

# Step 3: Verify Python dependencies (sqlite3 is stdlib, no install needed)
echo "[3/7] Verifying Python dependencies..."
python3 -c "import sqlite3; print('  [PASS] sqlite3 available')" 2>/dev/null || {
    echo "  [FAIL] sqlite3 not available"
    exit 1
}
echo ""

# Step 4: Configure API Key in local settings
echo "[4/7] Configuring executor profile..."
echo ""

if [ "$EXECUTOR_PROVIDER" = "claude-sonnet" ]; then
    mkdir -p .claude

    if [ ! -f ".claude/settings.opussonnet.local.json" ] && [ -f ".claude/settings.opussonnet.example.json" ]; then
        cp .claude/settings.opussonnet.example.json .claude/settings.opussonnet.local.json
    fi
    if [ ! -f ".claude/settings.sonnet-executor.local.json" ] && [ -f ".claude/settings.sonnet-executor.example.json" ]; then
        cp .claude/settings.sonnet-executor.example.json .claude/settings.sonnet-executor.local.json
    fi
    if [ ! -f ".claude/settings.opusminimax-planner.local.json" ] && [ -f ".claude/settings.opusminimax-planner.example.json" ]; then
        cp .claude/settings.opusminimax-planner.example.json .claude/settings.opusminimax-planner.local.json 2>/dev/null || true
    fi

    python3 - ".claude/settings.opussonnet.local.json" ".claude/settings.sonnet-executor.local.json" ".claude/settings.opusminimax-planner.local.json" "$PLANNER_MODEL" "$EXECUTOR_MODEL" "$PROFILE" <<'PY'
import json
import pathlib
import sys

opussonnet_path, sonnet_path, planner_path = map(pathlib.Path, sys.argv[1:4])
planner_model, executor_model, profile = sys.argv[4:7]
default_mode = "bypassPermissions" if profile == "solo-fast" else "acceptEdits"


def read_json(path: pathlib.Path, fallback: dict) -> dict:
    if path.is_file():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                return data
        except Exception:
            pass
    return json.loads(json.dumps(fallback))


def scrub_minimax(env: dict) -> None:
    for key in [
        "ANTHROPIC_BASE_URL",
        "ANTHROPIC_AUTH_TOKEN",
        "MINIMAX_API_KEY",
        "MINIMAX_API_HOST",
    ]:
        env.pop(key, None)


def ensure_perms(data: dict) -> None:
    perms = data.setdefault("permissions", {})
    if isinstance(perms, dict):
        perms["defaultMode"] = default_mode


opussonnet = read_json(opussonnet_path, {"profile": "opussonnet", "env": {}, "permissions": {}})
opussonnet["profile"] = "opussonnet"
opussonnet["model"] = "opusplan"
env = opussonnet.setdefault("env", {})
if not isinstance(env, dict):
    env = {}
    opussonnet["env"] = env
scrub_minimax(env)
env.update(
    {
        "ANTHROPIC_MODEL": "opusplan",
        "ANTHROPIC_DEFAULT_OPUS_MODEL": planner_model,
        "ANTHROPIC_DEFAULT_SONNET_MODEL": executor_model,
        "CLAUDE_CODE_SUBAGENT_MODEL": executor_model,
        "CLAUDE_CODE_EFFORT_LEVEL": "xhigh",
        "DISABLE_AUTOUPDATER": "1",
        "DISABLE_FEEDBACK_COMMAND": "1",
        "DISABLE_ERROR_REPORTING": "1",
        "DISABLE_AUTO_COMPACT": "0",
        "CLAUDE_CODE_NO_FLICKER": "1",
    }
)
ensure_perms(opussonnet)
opussonnet_path.write_text(json.dumps(opussonnet, indent=2) + "\n", encoding="utf-8")

sonnet = read_json(sonnet_path, {"profile": "sonnet-executor", "env": {}, "permissions": {}})
sonnet["profile"] = "sonnet-executor"
sonnet["model"] = executor_model
env = sonnet.setdefault("env", {})
if not isinstance(env, dict):
    env = {}
    sonnet["env"] = env
scrub_minimax(env)
env.update(
    {
        "ANTHROPIC_MODEL": executor_model,
        "ANTHROPIC_DEFAULT_SONNET_MODEL": executor_model,
        "CLAUDE_CODE_SUBAGENT_MODEL": executor_model,
        "CLAUDE_CODE_EFFORT_LEVEL": "high",
        "DISABLE_AUTOUPDATER": "1",
        "DISABLE_FEEDBACK_COMMAND": "1",
        "DISABLE_ERROR_REPORTING": "1",
        "DISABLE_AUTO_COMPACT": "0",
        "CLAUDE_CODE_NO_FLICKER": "1",
    }
)
ensure_perms(sonnet)
sonnet_path.write_text(json.dumps(sonnet, indent=2) + "\n", encoding="utf-8")

planner = read_json(planner_path, {"profile": "opusminimax-planner", "env": {}, "permissions": {}})
planner["profile"] = "opusminimax-planner"
env = planner.setdefault("env", {})
if not isinstance(env, dict):
    env = {}
    planner["env"] = env
scrub_minimax(env)
for key in ["ANTHROPIC_MODEL", "ANTHROPIC_DEFAULT_SONNET_MODEL", "ANTHROPIC_DEFAULT_HAIKU_MODEL"]:
    env.pop(key, None)
env.update(
    {
        "ANTHROPIC_DEFAULT_OPUS_MODEL": planner_model,
        "CLAUDE_CODE_EFFORT_LEVEL": "xhigh",
        "DISABLE_AUTOUPDATER": "1",
        "DISABLE_FEEDBACK_COMMAND": "1",
        "DISABLE_ERROR_REPORTING": "1",
        "DISABLE_AUTO_COMPACT": "0",
        "CLAUDE_CODE_NO_FLICKER": "1",
    }
)
ensure_perms(planner)
planner_path.write_text(json.dumps(planner, indent=2) + "\n", encoding="utf-8")
PY

    if [ ! -f ".claude/settings.local.json" ]; then
        cp .claude/settings.opussonnet.local.json .claude/settings.local.json
        echo "  [PASS] Claude Code default local profile set to opusplan"
    else
        echo "  [INFO] Preserved existing .claude/settings.local.json"
        echo "  [INFO] To launch this profile explicitly: claude --settings .claude/settings.opussonnet.local.json"
    fi

    echo "  [PASS] Opus planner pinned to $PLANNER_MODEL"
    echo "  [PASS] Sonnet executor pinned to $EXECUTOR_MODEL"
    echo "  [PASS] No MiniMax token or base URL is required for --mode opussonnet"
elif [ -n "$API_KEY" ] && [ "$API_KEY" != "YOUR_MINIMAX_API_KEY" ]; then
    mkdir -p .claude

    if [ "$SPLIT_EXECUTION_MODE" -eq 1 ]; then
        if [ ! -f ".claude/settings.minimax-executor.local.json" ] && [ -f ".claude/settings.minimax-executor.example.json" ]; then
            cp .claude/settings.minimax-executor.example.json .claude/settings.minimax-executor.local.json
        fi
        if [ ! -f ".claude/settings.minimax-executor.local.json" ]; then
            cat > .claude/settings.minimax-executor.local.json <<'EOF'
{
  "env": {},
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
EOF
        fi
        if [ ! -f ".claude/settings.opusminimax-planner.local.json" ] && [ -f ".claude/settings.opusminimax-planner.example.json" ]; then
            cp .claude/settings.opusminimax-planner.example.json .claude/settings.opusminimax-planner.local.json 2>/dev/null || true
        fi
        if [ ! -f ".claude/settings.opusminimax-planner.local.json" ]; then
            cat > .claude/settings.opusminimax-planner.local.json <<'EOF'
{
  "env": {},
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
EOF
        fi
    elif [ ! -f ".claude/settings.local.json" ]; then
        if [ -f ".claude/settings.minimax-executor.example.json" ]; then
            cp .claude/settings.minimax-executor.example.json .claude/settings.local.json
        elif [ -f ".claude/settings.json" ]; then
            cp .claude/settings.json .claude/settings.local.json
        else
            cat > .claude/settings.local.json <<'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.minimax.io/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "YOUR_MINIMAX_API_KEY",
    "MINIMAX_API_KEY": "YOUR_MINIMAX_API_KEY",
    "MINIMAX_API_HOST": "https://api.minimax.io",
    "API_TIMEOUT_MS": "3000000",
    "DISABLE_AUTOUPDATER": "1",
    "DISABLE_FEEDBACK_COMMAND": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "ANTHROPIC_MODEL": "MiniMax-M2.7-highspeed",
    "ANTHROPIC_SMALL_FAST_MODEL": "MiniMax-M2.7-highspeed",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2.7-highspeed",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2.7-highspeed",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2.7-highspeed",
    "CLAUDE_CODE_SUBAGENT_MODEL": "MiniMax-M2.7-highspeed",
    "CLAUDE_CODE_EFFORT_LEVEL": "high",
    "DISABLE_AUTO_COMPACT": "0",
    "MAX_THINKING_TOKENS": "1000",
    "CLAUDE_CODE_NO_FLICKER": "1"
  },
  "permissions": {
    "allow": [
      "WebFetch(domain:github.com)",
      "Bash(forgegod *)",
      "WebSearch",
      "mcp__MiniMax__web_search",
      "Bash(bash *.sh)"
    ],
    "defaultMode": "bypassPermissions"
  },
	  "hooks": {
	    "UserPromptSubmit": [
	      {
	        "hooks": [
	          {
	            "type": "command",
	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/time-anchor.sh\"",
	            "timeout": 3
	          }
	        ]
	      }
	    ],
	    "SessionStart": [
	      {
	        "matcher": "startup|resume|compact",
	        "hooks": [
	          {
	            "type": "command",
	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/time-anchor.sh\"",
	            "timeout": 3
	          },
	          {
	            "type": "command",
	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/state-sessionstart.sh\"",
            "timeout": 5
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "manual|auto",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/state-precompact.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "matcher": "manual|auto",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/state-postcompact.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/state-stop.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
EOF
        fi
    fi

    TARGET_SETTINGS=".claude/settings.local.json"
    if [ "$SPLIT_EXECUTION_MODE" -eq 1 ]; then
        TARGET_SETTINGS=".claude/settings.minimax-executor.local.json"
    fi

    python3 - "$API_KEY" "$TARGET_SETTINGS" "$EXECUTOR_MODEL" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[2])
data = json.loads(path.read_text())
env = data.setdefault("env", {})
key = sys.argv[1]
executor_model = sys.argv[3]

env["ANTHROPIC_BASE_URL"] = "https://api.minimax.io/anthropic"
env["ANTHROPIC_AUTH_TOKEN"] = key
env["MINIMAX_API_KEY"] = key
env["MINIMAX_API_HOST"] = "https://api.minimax.io"
env["ANTHROPIC_MODEL"] = executor_model
env["ANTHROPIC_SMALL_FAST_MODEL"] = executor_model
env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = executor_model
env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = executor_model
env["CLAUDE_CODE_SUBAGENT_MODEL"] = executor_model

path.write_text(json.dumps(data, indent=2) + "\n")
PY

    echo "  [PASS] API key configured in $TARGET_SETTINGS"

    if [ "$SPLIT_EXECUTION_MODE" -eq 1 ] && [ -f ".claude/settings.opusminimax-planner.local.json" ]; then
        python3 - ".claude/settings.opusminimax-planner.local.json" "$PLANNER_MODEL" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
env = data.setdefault("env", {})
env.pop("ANTHROPIC_BASE_URL", None)
env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = sys.argv[2]
env["CLAUDE_CODE_EFFORT_LEVEL"] = "xhigh"
path.write_text(json.dumps(data, indent=2) + "\n")
PY
        echo "  [PASS] Planner profile prepared in .claude/settings.opusminimax-planner.local.json"
    fi

    # Configure MCP server
    echo "Configuring MiniMax MCP server..."

    # Check if uvx exists
    UVX_PATH=""
    if command -v uvx &> /dev/null; then
        UVX_PATH="uvx"
    elif [ -f "$HOME/.local/bin/uvx" ]; then
        UVX_PATH="$HOME/.local/bin/uvx"
    elif [ -f "/usr/local/bin/uvx" ]; then
        UVX_PATH="/usr/local/bin/uvx"
    fi

    if [ -z "$UVX_PATH" ]; then
        echo "  [WARN] uvx not found. Installing..."
        curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || true
        if [ -f "$HOME/.local/bin/uvx" ]; then
            UVX_PATH="$HOME/.local/bin/uvx"
        fi
    fi

    if [ -n "$UVX_PATH" ]; then
        echo "  [INFO] Using uvx at: $UVX_PATH"
        if [ "$SPLIT_EXECUTION_MODE" -eq 1 ]; then
            echo "  [INFO] Opus split-execution mode does not mutate user-scope MCP automatically"
            echo "  [INFO] Use Claude Code project/local MCP config if you want MiniMax MCP tools"
        else
            # Remove existing MiniMax MCP if present
            claude mcp remove -s user MiniMax 2>/dev/null || true
            # Add with explicit path and verify
            claude mcp add -s user MiniMax \
              --env MINIMAX_API_KEY="$API_KEY" \
              --env MINIMAX_API_HOST=https://api.minimax.io \
              -- "$UVX_PATH" minimax-coding-plan-mcp -y
            echo "  [PASS] MiniMax MCP configured with $UVX_PATH"
        fi
    else
        echo "  [FAIL] Could not find or install uvx"
        echo "  Manual setup:"
        echo "    1. Install uvx: curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "    2. Then run: claude mcp add -s user MiniMax --env MINIMAX_API_KEY=$API_KEY -- uvx minimax-coding-plan-mcp -y"
    fi
else
    echo "To complete setup, rerun with your MiniMax Token Plan key:"
    echo ""
    echo "Clean/new folder:"
    echo "  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --minimax-key 'YOUR_TOKEN_PLAN_KEY'"
    echo ""
    echo "Existing project / updater:"
    echo "  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s -- --import-existing --minimax-key 'YOUR_TOKEN_PLAN_KEY'"
    echo ""
    echo "Get your key from: platform.minimax.io"
fi
echo ""

# Step 5: Initialize memory system directories
echo "[5/7] Initializing memory system..."
mkdir -p obsidian/Memory/Decisions
mkdir -p obsidian/Memory/Patterns
mkdir -p obsidian/Memory/Errors
mkdir -p obsidian/Memory/Stories/commits
mkdir -p obsidian/Memory/Dashboard
mkdir -p .taste/sessions
mkdir -p .taste/workflow-runs
mkdir -p .taste/specs
mkdir -p .minimaxing/state/events
mkdir -p .minimaxing/state/snapshots
echo "  [PASS] Memory directories created"

# Initialize taste system (taste files are defined later via /tastebootstrap)
# Only create directories, not the taste files themselves
if [ -f "./scripts/taste.sh" ]; then
    if [ "$COPIED_TEMPLATE_REPO" -eq 1 ] && [ ! -f "taste.md" ] && [ ! -f "taste.vision" ]; then
        echo "  [PASS] Bundled taste files removed for fresh bootstrap"
    fi
    echo "  [INFO] In a fresh repo, run /tastebootstrap to define taste.md and taste.vision"
fi
echo ""

# Step 5.5: Install git post-commit hook for auto-summarize
echo "[5.5/7] Installing git post-commit hook..."
if [ -d ".git" ]; then
    HOOK_DIR="$(pwd)/.git/hooks"
    mkdir -p "$HOOK_DIR"
    # Create post-commit hook that calls commit-summarize.sh
    cat > "${HOOK_DIR}/post-commit" <<'HOOK'
#!/bin/bash
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null)
SCRIPT_DIR="$(dirname "$0")/../../scripts"
if [ -f "${SCRIPT_DIR}/commit-summarize.sh" ]; then
    bash "${SCRIPT_DIR}/commit-summarize.sh" "$COMMIT_HASH" 2>/dev/null || true
fi
HOOK
    chmod +x "${HOOK_DIR}/post-commit"
    echo "  [PASS] Git post-commit hook installed"
else
    echo "  [SKIP] Not a git repository"
fi
echo ""

# Step 6: Add hardware detection to bashrc
echo "[6/7] Adding hardware auto-detection to ~/.bashrc..."
REPO_ROOT="$(pwd)"
DETECT_SOURCE="[ -f \"$REPO_ROOT/scripts/detect-hardware.sh\" ] && source \"$REPO_ROOT/scripts/detect-hardware.sh\" >/dev/null 2>&1"
if ! grep -q "detect-hardware.sh" ~/.bashrc 2>/dev/null; then
    echo "$DETECT_SOURCE" >> ~/.bashrc
    echo "  [PASS] Hardware auto-detection added to ~/.bashrc"
else
    echo "  [PASS] Hardware auto-detection already in ~/.bashrc"
fi
echo ""

# Step 7: Verify installation
echo "[7/7] Verifying harness..."
PASS=0

if command -v claude &> /dev/null; then
    echo "  [PASS] Claude Code installed"
    PASS=$((PASS+1))
else
    echo "  [WARN] Claude Code not installed - npm install -g @anthropic-ai/claude-code"
fi

if [ -d "memory" ] && [ -f "memory/sqlite_db.py" ]; then
    echo "  [PASS] Memory system installed"
    PASS=$((PASS+1))
else
    echo "  [WARN] Memory system not found"
fi

if [ -f "scripts/memory.sh" ]; then
    echo "  [PASS] Memory CLI available"
    PASS=$((PASS+1))
else
    echo "  [WARN] Memory CLI not found"
fi
echo ""

# Final status
echo "=========================================="
echo "  Setup Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run: claude"
echo "  2. If this is a fresh repo, run: /tastebootstrap"
if [ "$MODE" = "opusworkflow" ]; then
    echo "  3. Then try: /opusworkflow 'build a REST API'"
elif [ "$MODE" = "opusminimax" ]; then
    echo "  3. Then try: /opusminimax 'build a REST API'"
elif [ "$MODE" = "opussonnet" ]; then
    echo "  3. Then try: /opusworkflow 'build a REST API'"
    echo "     This uses the optional Claude-only opusplan profile: Opus planning + Sonnet execution."
else
    echo "  3. Legacy MiniMax-only override: /workflow 'build a REST API'"
fi
echo "  4. Check memory: bash scripts/memory.sh stats"
echo ""
