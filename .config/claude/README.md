# Claude Code Config

Personal Claude Code setup with a custom statusline and vim mode integration.

## Statusline

`statusline.sh` is a custom status bar script driven by JSON piped from Claude Code. All colors use the Catppuccin Mocha palette.

Segments left to right:

| Segment | Description |
|---------|-------------|
| `N` / `I` / `V` / `VL` | Vim mode — blue (normal), green (insert), yellow (visual) |
| ` main ±3` (git branch icon) | Git branch and uncommitted file count |
| ` sonnet-4-6` (claude icon) | Active Claude model |
| ` ▪▪▪` (effort icon) | Effort level with dot count — dimmed (low ▪) → yellow (medium ▪▪) → peach (high ▪▪▪ / xhigh ▪▪▪▪) → red (max ▪▪▪▪▪) |
| `⚡` | Fast mode active |
| `▪▪▪▫▫▫▫▫▫▫ 30%` | Context window usage (10-segment bar) — overlay (0–49%) → yellow (50%) → peach (75%) → red (90%) |

Configured in `settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "~/.config/claude/statusline.sh",
  "hideVimModeIndicator": true
}
```

## AI-Helpful CLI Tools

Tools installed to give Claude better ways to read, search, and modify code.

| Tool | Purpose |
|------|---------|
| **difftastic** | Structural diff — understands syntax trees so diffs show what logically changed, not just line deltas. |
| **ast-grep** | AST-aware code search and rewriting — find patterns across languages without regex hacks. |
| **shellcheck** | Static analysis for shell scripts — catches bugs, bad practices, and portability issues. |
| **sd** | Simpler `sed` replacement for find-and-replace. Supports regex and literal strings. |
| **scc** | Fast code counter (lines, blanks, comments, complexity) — quick codebase overview. |
| **yq** | `jq` for YAML, JSON, TOML, and XML. Read and edit config files in pipelines. |
| **jq** | JSON parsing and transformation in pipelines. Used by the statusline script. |
| **fd** | Fast `find` replacement with cleaner syntax and sane defaults. |
| **rg** | Fast recursive text search — smarter defaults than `grep`. |
| **bat** | `cat` with syntax highlighting and line numbers. |
| **eza** | Modern `ls` with icons, git status, and tree views. |
| **glow** | Render markdown in the terminal with formatting and layout. |
| **delta** | Syntax-highlighted diff renderer — wired into git config automatically. |

## Dependencies

- `tmux` — required for popup features
- Nerd Fonts — required for all icons in the statusline

## File Structure

```
~/.config/claude/
├── settings.json                   # theme, vim mode, statusline, hooks
├── statusline.sh                   # custom status bar script
├── hooks/                          # hook scripts
├── skills/                         # skill definitions (e.g. health-check)
└── memory/                         # persistent memory across sessions
```
