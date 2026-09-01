# Claude Code Config

Personal Claude Code setup with a custom statusline and vim mode integration.

> **Machine setup / bootstrap / how to add MCP servers, hooks, profiles:** see
> [`../AI-SETUP.md`](../AI-SETUP.md) — the cross-tool runbook for Claude + Codex.

## Statusline

`statusline.sh` is a custom status bar script driven by JSON piped from Claude Code. All colors use the Catppuccin Mocha palette.

Segments left to right:

| Segment                      | Description                                                                                                         |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `N` / `I` / `V` / `VL`       | Vim mode — blue (normal), green (insert), yellow (visual)                                                           |
| ` main ±3` (git branch icon) | Git branch and uncommitted file count                                                                               |
| ` sonnet-4-6` (claude icon)  | Active Claude model                                                                                                 |
| ` ▪▪▪` (effort icon)         | Effort level with dot count — dimmed (low ▪) → yellow (medium ▪▪) → peach (high ▪▪▪ / xhigh ▪▪▪▪) → red (max ▪▪▪▪▪) |
| `⚡`                         | Fast mode active                                                                                                    |
| `▪▪▪▫▫▫▫▫▫▫ 30%`             | Context window usage (10-segment bar) — overlay (0–49%) → yellow (50%) → peach (75%) → red (90%)                    |

Configured in `settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "~/.config/claude/statusline.sh",
  "hideVimModeIndicator": true
}
```

## AI-Helpful CLI Tools

The canonical tool table (what each tool replaces and when to reach for it) lives in [`CLAUDE.md`](CLAUDE.md) in this directory; the install list is the Brewfile.

## Dependencies

- `tmux` — required for popup features
- Nerd Fonts — required for all icons in the statusline

## File Structure

```
~/.config/claude/
├── CLAUDE.md                       # portable agent behavior (machine setup lives in ../AI-SETUP.md)
├── settings.json                   # theme, vim mode, statusline, hooks, permissions, autoMode, sandbox, plugins
├── statusline.sh                   # custom status bar script
├── hooks/
│   ├── dispatch.sh -> ../../../.local/bin/ai-hook-dispatch   # symlink to shared dispatcher
│   ├── handlers/                   # per-event executables
│   └── logs/                       # hook run logs
├── skills/                         # skill definitions (health-check)
└── projects/                       # per-cwd session + auto-memory state (gitignored)
```

Everything tracked here is meant to be **generic**: no project names, tenant hosts, repo paths, or
ticket keys. Project-specific guidance belongs in that repo's own `AGENTS.md` / `.claude/rules/`.

Claude's skill set is deliberately smaller than Codex's — see the parity table in
[`../AI-SETUP.md`](../AI-SETUP.md) for the documented Codex-only exemptions before "fixing" a gap.
