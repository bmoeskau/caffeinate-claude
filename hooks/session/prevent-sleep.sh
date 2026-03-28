#!/bin/bash

# Prevent Mac from sleeping while any Claude Code session is running.
# Uses a reference counter so caffeinate stays alive across multiple sessions.

[ -z "$CLAUDE_STAY_AWAKE" ] && exit 0

COUNTER_FILE="/tmp/claude_caffeinate_session.count"
PID_FILE="/tmp/claude_caffeinate_session.pid"

# Increment session counter
count=0
if [ -f "$COUNTER_FILE" ]; then
    count=$(cat "$COUNTER_FILE")
fi
count=$((count + 1))
echo "$count" > "$COUNTER_FILE"

# If caffeinate is already running, nothing more to do
if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null 2>&1 && ps -p "$pid" -o args= | grep -q '^caffeinate'; then
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Start caffeinate with no timeout (runs until killed)
# -d: prevent display sleep  -i: prevent idle sleep
nohup caffeinate -d -i > /dev/null 2>&1 &
echo $! > "$PID_FILE"
