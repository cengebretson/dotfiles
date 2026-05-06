# Claude Code Config

Personal Claude Code setup with a custom statusline and a diff review popup triggered after each response.

## Statusline

`statusline.sh` is a custom status bar script driven by JSON piped from Claude Code. All colors use the Catppuccin Mocha palette.

Segments left to right:

| Segment | Description |
|---------|-------------|
| `N` / `I` / `V` / `VL` | Vim mode — blue (normal), green (insert), yellow (visual) |
| `󰘬 main ±3` | Git branch and uncommitted file count |
| `󱙺 sonnet-4-6` | Active Claude model |
| `󰾆 ■■■□` | Effort level — dimmed (low) → yellow (medium) → peach (high) → red (max) |
| `󰛨` | Extended thinking enabled — same color as effort level |
| `⚡` | Fast mode active (Max plan) |
| `▓▓░░░░░░░░ 15%` | Context window usage — color escalates yellow → peach → red above 50/75/90% |
| `󰈈` | Diff popup is on (only shown when enabled) |

Configured in `settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "~/.config/claude/statusline.sh",
  "hideVimModeIndicator": true
}
```

## Diff Review Popup

After Claude finishes a response, if any files were edited a tmux popup opens showing the changed files alongside a delta diff preview.

### How it works

1. **`hooks/track-changes.sh`** — `PostToolUse` hook that fires after every Edit/Write. Records the changed file path to `/tmp/claude-changes-{session_id}`.
2. **`hooks/diff-popup.sh`** — `Stop` hook that fires when Claude finishes responding. Reads the tracked files, opens a tmux popup running the viewer.
3. **`hooks/diff-viewer.sh`** — fzf interface showing changed files (30%) with a delta diff preview (70%). File paths are displayed relative to `$HOME`.
4. **`hooks/diff-preview.sh`** — called by fzf for each file. Diffs tracked files against HEAD; shows full content for new untracked files. Uses `--file-style omit --hunk-header-style omit` to show only changed code.

### Keybindings in the popup

| Key | Action |
|-----|--------|
| `enter` | Open selected file in nvim (returns to popup on quit) |
| `ctrl-u` / `ctrl-d` | Scroll diff half page up/down |
| `shift-↑` / `shift-↓` | Scroll diff line by line |
| `esc` / `q` | Close popup |

### Toggle

```fish
claude_diff   # toggle diff popup on/off
```

The toggle state is a flag file at `~/.config/claude/flags/diff-popup`. When active, a `󰈈` icon appears in the statusline.

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
- `fzf` — file picker in the diff popup
- `delta` — diff renderer (uses your git config theme automatically)
- `tmux` — required for the popup; falls back to inline fzf otherwise
- Nerd Fonts — required for all icons in the statusline

## File Structure

```
~/.config/claude/
├── settings.json          # theme, vim mode, statusline, hooks
├── statusline.sh          # custom status bar script
├── hooks/
│   ├── track-changes.sh   # PostToolUse: record edited files
│   ├── diff-popup.sh      # Stop: launch the tmux popup
│   ├── diff-viewer.sh     # fzf file picker with preview
│   └── diff-preview.sh    # delta diff renderer for fzf preview
├── flags/
│   └── diff-popup         # exists = popup enabled (toggled by claude_diff)
└── memory/                # persistent memory across sessions
```
