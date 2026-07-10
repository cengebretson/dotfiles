# Tmux Attention Marker

Generic attention marker for terminal agents running inside tmux. An agent hook (or a human) sets a typed state in the `@agent_attention` window option and an event-specific icon appears in the window tab; the marker clears shortly after the window is actually viewed. This shipped as the versioned tmux plugin `cengebretson/tmux-attention` — declared in `tmux.conf` via `set -g @plugin 'cengebretson/tmux-attention'` and installed under `~/.config/tmux/plugins/tmux-attention/`.

States and default icons (from `plugins/tmux-attention/tmux-attention.tmux`):

| State | Icon | Intended Use |
|-------|------|--------------|
| `input` | `󱐋` | Agent needs user input |
| `blocked` | `` | Agent is blocked or hit an error requiring intervention |
| `review` | `󰛨` | Agent has output ready for review |
| `done` | `` | Agent finished a task |
| `clear` | none | Clear the marker |

## CLI

The portable CLI is `~/.config/tmux/plugins/tmux-attention/scripts/tmux-attention`. Subcommands: a state (`input|blocked|review|done|clear`; no state defaults to `input`; `--target` selects a tmux target), `event <event>` (e.g. `approval_required`, `task_complete`), `get`, `list`, `status-format`, `catppuccin-format`, `doctor [--probe]`, and `version`.

## Hook Wiring

Claude and Codex hooks route through the shared dispatcher `~/.local/bin/ai-hook-dispatch` (symlinked as each tool's `hooks/dispatch.sh`) to handler shims that exec the plugin CLI:

| Handler | CLI call |
|---------|----------|
| `~/.config/claude/hooks/handlers/notification` | `input` |
| `~/.config/claude/hooks/handlers/stop-failure` | `blocked` |
| `~/.config/claude/hooks/handlers/prompt-clear` | `clear` |
| `~/.config/codex/hooks/handlers/permission-request-notify` | `input` |
| `~/.config/codex/hooks/handlers/prompt-clear` | `clear` |

For icon/behavior options, clear-on-view hook details, hook installation, and tests, see the plugin's own docs: `plugins/tmux-attention/README.md` and `plugins/tmux-attention/docs/hooks.md`.
