#!/bin/bash

# Re-enable Mac sleep after Claude finishes working on a response.
# Adapted from: https://tngranados.com/blog/preventing-mac-sleep-claude-code/

PID_FILE="/tmp/claude_caffeinate_cmd.pid"

if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null 2>&1 && ps -p "$pid" -o args= | grep -q '^caffeinate'; then
        kill "$pid" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi
