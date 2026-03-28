#!/bin/bash

# Re-enable Mac sleep when the last Claude Code session ends.
# Decrements the session counter; only kills caffeinate when it reaches zero.

COUNTER_FILE="/tmp/claude_caffeinate_session.count"
PID_FILE="/tmp/claude_caffeinate_session.pid"

# Decrement session counter
count=0
if [ -f "$COUNTER_FILE" ]; then
    count=$(cat "$COUNTER_FILE")
fi
count=$((count - 1))
if [ "$count" -le 0 ]; then
    count=0
    rm -f "$COUNTER_FILE"
else
    echo "$count" > "$COUNTER_FILE"
fi

# Only kill caffeinate if no sessions remain
if [ "$count" -eq 0 ] && [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null 2>&1 && ps -p "$pid" -o args= | grep -q '^caffeinate'; then
        kill "$pid" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi
