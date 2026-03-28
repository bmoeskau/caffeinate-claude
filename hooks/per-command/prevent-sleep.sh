#!/bin/bash

# Prevent Mac from sleeping while Claude is actively working on a response.
# Starts caffeinate on each prompt submission; kills it when Claude stops.
# Adapted from: https://tngranados.com/blog/preventing-mac-sleep-claude-code/

PID_FILE="/tmp/claude_caffeinate_cmd.pid"
SESSION_PID_FILE="/tmp/claude_caffeinate_session.pid"

# If session-level caffeinate is already running, skip — it's a superset
if [ -f "$SESSION_PID_FILE" ]; then
    pid=$(cat "$SESSION_PID_FILE")
    if ps -p "$pid" > /dev/null 2>&1 && ps -p "$pid" -o args= | grep -q '^caffeinate'; then
        exit 0
    fi
fi

# Kill any existing per-command caffeinate (stale from a previous prompt)
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    if ps -p "$old_pid" > /dev/null 2>&1 && ps -p "$old_pid" -o args= | grep -q '^caffeinate'; then
        kill "$old_pid" 2>/dev/null
    fi
    rm -f "$PID_FILE"
fi

# Start caffeinate with a timeout (default: 1 hour)
timeout="${CAFFEINATE_TIMEOUT:-3600}"
nohup caffeinate -i -t "$timeout" > /dev/null 2>&1 &
echo $! > "$PID_FILE"
