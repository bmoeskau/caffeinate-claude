# caffeinate-claude

Prevent your Mac from falling asleep in [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
remote-control sessions or during long-running commands. Uses the built-in
MacOS `caffeinate` utility.

## Strategies

### Per-Command (Recommended Default)

Keeps your Mac awake only while Claude is actively working on a response. Useful
when executing autonomous agents within Claude Code, or kicking off any long-running
commands where you might step away from the computer.

Starts `caffeinate` when you submit a prompt, kills it when Claude stops.

- **Hooks:** `UserPromptSubmit` / `Stop`
- **Timeout:** 1 hour default, configurable via `CAFFEINATE_TIMEOUT` env var
- **No setup required** — works out of the box

### Session-Level (Opt-In)

Keeps your Mac awake during an entire Claude Code session. Useful for
[remote-control](https://code.claude.com/docs/en/remote-control)
sessions where you want the Mac to stay awake even when idle for the
entire duration of the session.

Uses reference counting so multiple concurrent sessions share a single
`caffeinate` process — it only terminates when the last session ends.

- **Hooks:** `SessionStart` / `SessionEnd`
- **Gate:** Only activates when `CLAUDE_STAY_AWAKE=1` is set

### Using Both

The two strategies coexist safely:

- **Separate PID files** — per-command uses `/tmp/claude_caffeinate_cmd.pid`,
  per-session uses `/tmp/claude_caffeinate_session.pid`
- **Session takes precedence** — when a session-level caffeinate is running,
  the per-command hook skips starting its own (session-level is a superset)
- **No conflicts** — each strategy manages its own lifecycle independently

## Installation

### 1. Copy the hook scripts

```bash
# Create the hooks directories
mkdir -p ~/.claude/hooks/per-command
mkdir -p ~/.claude/hooks/session

# Copy the scripts you want
# Per-command (recommended):
cp hooks/per-command/*.sh ~/.claude/hooks/per-command/

# Session-level (optional):
cp hooks/session/*.sh ~/.claude/hooks/session/

# Make them executable
chmod +x ~/.claude/hooks/per-command/*.sh
chmod +x ~/.claude/hooks/session/*.sh
```

### 2. Configure Claude Code to use the hooks

Add the hook configuration to your `~/.claude/settings.json`. Choose the config
that matches your setup:

- **Per-command only:** Copy from [`examples/per-command.json`](examples/per-command.json)
- **Session only:** Copy from [`examples/session.json`](examples/session.json)
- **Both:** Copy from [`examples/combined.json`](examples/combined.json)

Merge the `hooks` key into your existing `settings.json`. For example, to use
per-command only:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/per-command/prevent-sleep.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/per-command/allow-sleep.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. (Session-level only) Set the environment variable

Session-level hooks are gated behind an environment variable so that they only
activate when intended, e.g. when going remote and walking away from the computer.
The most convenient setup is to add an alias to your shell config that you would
use to start a new remote-control Claude session:

```bash
# Add to ~/.zshrc or ~/.bashrc
alias claude-remote='CLAUDE_STAY_AWAKE=1 claude --remote-control'
```

### 4. (Optional) Customize the per-command timeout

Per-command caffeinate defaults to a 1-hour timeout. Howver, if you work with
long-running commands that could exceed that, the default timeout can be
customized by setting the environment variable `CAFFEINATE_TIMEOUT` in your
shell config (value in seconds):

```bash
# Add to ~/.zshrc or ~/.bashrc
export CAFFEINATE_TIMEOUT=7200  # 2 hours
```

## How It Works

Both strategies use macOS [`caffeinate`](https://ss64.com/mac/caffeinate.html)
to prevent the system from going to sleep.

### PID Safety

When killing a `caffeinate` process, the scripts verify the PID still belongs
to a `caffeinate` process before sending the signal. This prevents accidentally
killing an unrelated process if the OS has recycled the PID:

```bash
if ps -p "$pid" -o args= | grep -q '^caffeinate'; then
    kill "$pid" 2>/dev/null
fi
```

### Reference Counting (Session-Level)

Multiple concurrent Claude Code sessions share a single `caffeinate` process.
A counter file tracks active sessions:

1. **Session starts** → counter increments. If caffeinate isn't running, start it.
2. **Session ends** → counter decrements. If counter hits zero, kill caffeinate.

This prevents the race condition where closing one session kills caffeinate while
another remote session is still active.

## Credits

Per-command strategy adapted from
[Preventing Mac Sleep with Claude Code](https://tngranados.com/blog/preventing-mac-sleep-claude-code/)
by Toni Granados, with PID safety improvements and session-level support added.

## License

[MIT](LICENSE)
