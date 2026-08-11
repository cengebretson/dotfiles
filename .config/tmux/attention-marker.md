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

While an agent turn is active, `@tmux_attention_tab_icon` renders `󰚩`. An
attention state takes precedence over that working icon. The local Catppuccin
tab formats use this compact icon in place of the numbered-square glyph, then
fall back to the number when neither state is present.

The portable CLI is `~/.config/tmux/plugins/tmux-attention/scripts/tmux-attention`. Subcommands: a state (`input|blocked|review|done|clear`; no state defaults to `input`; `--target` selects a tmux target), `event <event>` (e.g. `approval_required`, `task_complete`), `get`, `list`, `turn-start`, `turn-active`, `turn-stop`, `turn-done`, `status-format`, `catppuccin-format`, `doctor [--probe]`, and `version`.

## Hook Wiring

Claude and Codex hooks route through the shared dispatcher `~/.local/bin/ai-hook-dispatch` (symlinked as each tool's `hooks/dispatch.sh`) to handler shims that exec the plugin CLI:

| Tool | Hook event | Handler | CLI call |
|------|-----------|---------|----------|
| Claude | `Notification` | `notification` | `input` |
| Claude | `StopFailure` | `stop-failure` | `blocked` |
| Claude | `UserPromptSubmit` | `prompt-clear` | `turn-start` |
| Claude | `Stop` | `agent-turn-stop` | `turn-done --source claude --reason response_ready` |
| Codex | `PreToolUse` | `agent-turn-active` | `turn-active` |
| Codex | `PermissionRequest` | `permission-request-notify` | `input` |
| Codex | `UserPromptSubmit` | `prompt-clear` | `turn-start` |
| Codex | `Stop` | `agent-turn-stop` | `turn-done --source codex --reason response_ready` |

`turn-start` sets the window's agent context and clears any pending marker;
`turn-done` releases it and marks the response ready. Codex can emit an
intermediate `Stop` while an automatic continuation is still working, so the
next `PreToolUse` calls idempotent `turn-active` to restore the working state.

For icon/behavior options, clear-on-view hook details, hook installation, and tests, see the plugin's own docs: `plugins/tmux-attention/README.md` and `plugins/tmux-attention/docs/hooks.md`.
