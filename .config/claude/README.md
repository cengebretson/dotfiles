# Claude Code Config

Personal Claude Code setup with a custom statusline, a persistent diff review side pane, and vim mode integration.

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

## Diff Review Side Pane

Powered by [claude-code-preview](https://github.com/cengebretson/claude-code-preview) — a Go bubbletea TUI that shows changed files and delta diffs after each Claude response. Open it with `prefix+P`.

### How it works

A single hook script (`hooks/claude-code-preview.sh`) handles all three events:

1. **PreToolUse** — snapshots each file before Claude edits it (once per file per session, preserving the original)
2. **PostToolUse** — records edited file paths
3. **Stop** — signals the TUI with the list of changed files

Multiple edits to the same file in one response show as a single net diff.

### Keybindings

| Key | Action |
|-----|--------|
| `↑` / `k` / `↓` / `j` | Navigate files |
| `enter` | Open in `$VISUAL` / `$EDITOR` (tmux popup by default) |
| `u` / `U` | Restore current file / all files from snapshot |
| `s` | Toggle side-by-side diff |
| `y` | Copy file path to clipboard |
| `r` | Refresh diff |
| `q` | Clear / quit |
| `?` | Show keybindings help |

### Tmux binding

| Binding | Action |
|---------|--------|
| `prefix+P` | Open preview pane (or unzoom if already open) |

## Gallery

![Claude Code statusline and diff popup](../assets/statusline.png)

## AI-Helpful CLI Tools

Tools installed to give Claude better ways to read, search, and modify code.

| Tool | Install | Purpose |
|------|---------|---------|
| **difftastic** | `brew install difftastic` | Structural diff — understands syntax trees so diffs show what logically changed, not just line deltas. Great for reviewing refactors. |
| **ast-grep** | `brew install ast-grep` | AST-aware code search and rewriting. Like grep but understands code structure — find patterns across languages without regex hacks. |
| **shellcheck** | `brew install shellcheck` | Static analysis for shell scripts. Catches bugs, bad practices, and portability issues before they cause problems. |
| **sd** | `brew install sd` | Simpler, faster `sed` replacement for find-and-replace. Supports regex and literal strings with cleaner syntax. |
| **scc** | `brew install scc` | Fast code counter (lines, blanks, comments, complexity). Gives a quick codebase overview without cloning context. |
| **yq** | `brew install yq` | `jq` for YAML, JSON, TOML, and XML. Useful for reading and editing config files in pipelines. |

## Dependencies

- `jq` — JSON parsing in statusline and hooks
- `delta` — diff renderer (uses your git config theme automatically)
- `tmux` — required for the preview pane
- Nerd Fonts — required for all icons in the statusline

## File Structure

```
~/.config/claude/
├── settings.json                   # theme, vim mode, statusline, hooks
├── statusline.sh                   # custom status bar script
├── hooks/
│   └── claude-code-preview.sh      # single hook handling PreToolUse, PostToolUse, Stop
└── memory/                         # persistent memory across sessions
```
