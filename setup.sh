#!/bin/bash
# minmaxing - One-Command Setup
# Usage: curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash
# Or with API key: curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY

set -e

API_KEY="${1:-}"

echo "=========================================="
echo "  minmaxing Setup"
echo "=========================================="
echo ""

# Step 0: Clone repository to temp, then move to current directory
if [ ! -d ".git" ]; then
    echo "[0/7] Cloning minmaxing repository..."
    TEMP_DIR=$(mktemp -d)
    git clone https://github.com/waitdeadai/minmaxing.git "$TEMP_DIR"
    cp -r "$TEMP_DIR"/* .
    cp -r "$TEMP_DIR"/.[!.]* . 2>/dev/null || true
    rm -rf "$TEMP_DIR"
else
    echo "[0/7] Using existing minmaxing directory"
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
echo "[4/7] Configuring MiniMax API key..."
echo ""

if [ -n "$API_KEY" ] && [ "$API_KEY" != "YOUR_MINIMAX_API_KEY" ]; then
    mkdir -p .claude

    if [ ! -f ".claude/settings.local.json" ]; then
        if [ -f ".claude/settings.json" ]; then
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
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
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
  }
}
EOF
        fi
    fi

    python3 - "$API_KEY" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(".claude/settings.local.json")
data = json.loads(path.read_text())
env = data.setdefault("env", {})
key = sys.argv[1]

env["ANTHROPIC_BASE_URL"] = "https://api.minimax.io/anthropic"
env["ANTHROPIC_AUTH_TOKEN"] = key
env["MINIMAX_API_KEY"] = key
env["MINIMAX_API_HOST"] = "https://api.minimax.io"

path.write_text(json.dumps(data, indent=2) + "\n")
PY

    echo "  [PASS] API key configured in .claude/settings.local.json"

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
        # Remove existing MiniMax MCP if present
        claude mcp remove -s user MiniMax 2>/dev/null || true
        # Add with explicit path and verify
        claude mcp add -s user MiniMax \
          --env MINIMAX_API_KEY="$API_KEY" \
          --env MINIMAX_API_HOST=https://api.minimax.io \
          -- "$UVX_PATH" minimax-coding-plan-mcp -y
        echo "  [PASS] MiniMax MCP configured with $UVX_PATH"
    else
        echo "  [FAIL] Could not find or install uvx"
        echo "  Manual setup:"
        echo "    1. Install uvx: curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "    2. Then run: claude mcp add -s user MiniMax --env MINIMAX_API_KEY=$API_KEY -- uvx minimax-coding-plan-mcp -y"
    fi
else
    echo "To complete setup, run with your API key:"
    echo ""
    echo "  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY"
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
echo "  [PASS] Memory directories created"

# Initialize taste system (taste files are defined later via /tastebootstrap)
# Only create directories, not the taste files themselves
if [ -f "./scripts/taste.sh" ]; then
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
echo "  3. Then try: /workflow 'build a REST API'"
echo "  4. Check memory: bash scripts/memory.sh stats"
echo ""
