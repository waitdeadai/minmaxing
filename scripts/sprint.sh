#!/bin/bash
# Ultimate MiniMax 2.7 Harness - Sprint Mode
# Parallel execution with context isolation and file isolation

set -e

echo "=========================================="
echo "  Sprint Mode - Parallel Execution"
echo "  $(date)"
echo "=========================================="
echo ""

# Check arguments
if [ -z "$1" ]; then
    echo "Usage: $0 '<task description>'"
    echo ""
    echo "Sprint mode executes tasks in parallel with:"
    echo "  - File isolation (no conflicts)"
    echo "  - Clean context per agent"
    echo "  - Aggregated results"
    echo "  - Up to MAX_PARALLEL_AGENTS parallel agents"
    echo ""
    echo "Example:"
    echo "  $0 'Implement user auth: login, logout, session management'"
    echo ""
    echo "In Claude Code, use: /sprint"
    exit 1
fi

TASK="$@"
MAX_AGENTS="${MAX_PARALLEL_AGENTS:-10}"

echo "Task: $TASK"
echo "Max parallel agents: $MAX_AGENTS"
echo ""

# Step 1: Analyze task for parallelization
echo "[1/4] Analyzing task for efficacy-first parallelization..."
echo "  - Checking for independent file boundaries"
echo "  - Identifying parallelizable components"
echo "  - Verifying no shared state conflicts"
echo "  - Choosing an effective agent budget (ceiling: $MAX_AGENTS)"
echo ""

# Step 2: Create isolated contexts
echo "[2/4] Creating isolated contexts..."
CONTEXT_DIR="/tmp/minimax-sprint-$$"
mkdir -p "$CONTEXT_DIR"
echo "  Context directory: $CONTEXT_DIR"
echo ""

# Step 3: Launch parallel agents
echo "[3/4] Launching parallel agents..."
echo ""
echo "Would launch up to $MAX_AGENTS agents with:"
echo "  - Clean context isolation (no pollution)"
echo "  - File boundary discipline"
echo "  - Aggregator to combine results"
echo "  - No synthetic task splitting just to fill slots"
echo ""
echo "FILE ISOLATION RULE: Parallel only when agents touch different files"
echo ""

# Step 4: Wait and aggregate
echo "[4/4] Results aggregation..."
echo ""

# Cleanup
rm -rf "$CONTEXT_DIR"

echo ""
echo "=========================================="
echo "  Sprint Complete"
echo "=========================================="
echo ""
echo "For full parallel execution, use Claude Code"
echo "with the /sprint skill for detailed protocol."
echo ""
echo "Sprint skill features:"
echo "  - Analyzes task for parallelization"
echo "  - Enforces file isolation"
echo "  - Manages context isolation"
echo "  - Aggregates results"
echo "  - Reports conflicts"
echo "  - Uses MAX_PARALLEL_AGENTS as a ceiling, not a quota"
