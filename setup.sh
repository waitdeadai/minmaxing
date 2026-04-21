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

# Step 4: Configure API Key in settings.json
echo "[4/7] Configuring MiniMax API key..."
echo ""

if [ -n "$API_KEY" ] && [ "$API_KEY" != "YOUR_MINIMAX_API_KEY" ]; then
    # Update settings.json with the actual API key
    if [ -f ".claude/settings.json" ]; then
        sed -i "s/YOUR_MINIMAX_API_KEY/$API_KEY/g" .claude/settings.json
        echo "  [PASS] API key configured in .claude/settings.json"
    else
        echo "  [WARN] .claude/settings.json not found"
    fi

    # Configure MCP server
    echo "Configuring MiniMax MCP server..."
    claude mcp add -s user MiniMax \
      --env MINIMAX_API_KEY="$API_KEY" \
      --env MINIMAX_API_HOST=https://api.minimax.io \
      -- uvx minimax-coding-plan-mcp -y 2>/dev/null || echo "MCP setup skipped (may already exist)"
    echo "  [PASS] MiniMax MCP configured"
else
    echo "To complete setup, run with your API key:"
    echo ""
    echo "  curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash -s YOUR_TOKEN_PLAN_KEY"
    echo ""
    echo "Or manually configure with:"
    echo "  claude mcp add -s user MiniMax \\"
    echo "    --env MINIMAX_API_KEY=YOUR_TOKEN_PLAN_KEY \\"
    echo "    --env MINIMAX_API_HOST=https://api.minimax.io \\"
    echo "    -- uvx minimax-coding-plan-mcp -y"
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
echo "  [PASS] Memory directories created"

# Initialize taste system (NOTE: taste files created on-demand by /workflow via /align --bootstrap)
# Only create directories, not the taste files themselves
if [ -f "./scripts/taste.sh" ]; then
    echo "  [INFO] Taste files will be created by /align --bootstrap when you first run /workflow"
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
DETECT_SOURCE="[ -f \"\$(pwd)/scripts/detect-hardware.sh\" ] && source \"\$(pwd)/scripts/detect-hardware.sh\""
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
echo "  2. Try: /workflow 'build a REST API'"
echo "  3. Check memory: bash scripts/memory.sh stats"
echo ""
