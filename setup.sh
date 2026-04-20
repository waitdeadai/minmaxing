#!/bin/bash
# minmaxing - One-Command Setup
# Usage: curl -fsSL https://raw.githubusercontent.com/waitdeadai/minmaxing/main/setup.sh | bash

set -e

echo "=========================================="
echo "  minmaxing Setup"
echo "=========================================="
echo ""

# Step 1: Install ForgeGod
echo "[1/4] Installing ForgeGod memory system..."
pip install forgegod --break-system-packages 2>/dev/null || pip3 install forgegod --break-system-packages 2>/dev/null || echo "ForgeGod install failed (will retry later)"
echo ""

# Step 2: Install uvx
echo "[2/4] Checking uvx..."
if ! command -v uvx &> /dev/null; then
    echo "Installing uvx..."
    curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || echo "uvx install skipped"
    source ~/.bashrc 2>/dev/null || true
fi
echo ""

# Step 3: Verify installation
echo "[3/4] Verifying installation..."
PASS=0
if command -v forgegod &> /dev/null; then
    echo "  [PASS] ForgeGod installed"
    PASS=$((PASS+1))
else
    echo "  [WARN] ForgeGod not installed - run: pip install forgegod --break-system-packages"
fi

if command -v claude &> /dev/null; then
    echo "  [PASS] Claude Code installed"
    PASS=$((PASS+1))
else
    echo "  [WARN] Claude Code not installed - npm install -g @anthropic-ai/claude-code"
fi

if command -v uvx &> /dev/null; then
    echo "  [PASS] uvx installed"
    PASS=$((PASS+1))
else
    echo "  [WARN] uvx not installed - curl -LsSf https://astral.sh/uv/install.sh | sh"
fi
echo ""

# Step 4: Configure MiniMax MCP
echo "[4/4] MiniMax MCP Configuration"
echo ""
echo "To complete setup, run:"
echo ""
echo "  claude mcp add -s user MiniMax \\"
echo "    --env MINIMAX_API_KEY=YOUR_TOKEN_PLAN_KEY \\"
echo "    --env MINIMAX_API_HOST=https://api.minimax.io \\"
echo "    -- uvx minimax-coding-plan-mcp -y"
echo ""
echo "Replace YOUR_TOKEN_PLAN_KEY with your key from platform.minimax.io"
echo ""

# Final status
echo "=========================================="
echo "  Setup Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Configure MiniMax MCP (command above)"
echo "  2. Run: ./scripts/start-session.sh"
echo "  3. Run: ./scripts/test-harness.sh"
echo "  4. Start coding with: claude"
echo ""
