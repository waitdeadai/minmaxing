#!/bin/bash
# Auto-detect hardware and set MAX_PARALLEL_AGENTS
# Run this at session start to configure agent pool

detect_agents() {
    local ram_gb=$(free -g 2>/dev/null | grep Mem | awk '{print $2}' || echo "8")
    local cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")
    local agents=3  # conservative default

    if [ "$ram_gb" -ge 32 ] && [ "$cores" -ge 8 ]; then
        agents=10
    elif [ "$ram_gb" -ge 16 ] && [ "$cores" -ge 4 ]; then
        agents=6
    elif [ "$ram_gb" -ge 8 ] && [ "$cores" -ge 2 ]; then
        agents=3
    else
        agents=2
    fi

    echo "$agents"
}

export MAX_PARALLEL_AGENTS=$(detect_agents)

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "Detected hardware: $(nproc 2>/dev/null || echo '?') cores, $(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo '?') RAM"
    echo "MAX_PARALLEL_AGENTS=$MAX_PARALLEL_AGENTS"
fi
