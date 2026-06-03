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

| Tool | Install | Purpose |
|------|---------|---------|
| **difftastic** | `brew install difftastic` | Structural diff — understands syntax trees so diffs show what logically changed, not just line deltas. Great for reviewing refactors. |
| **ast-grep** | `brew install ast-grep` | AST-aware code search and rewriting. Like grep but understands code structure — find patterns across languages without regex hacks. |
| **shellcheck** | `brew install shellcheck` | Static analysis for shell scripts. Catches bugs, bad practices, and portability issues before they cause problems. |
| **sd** | `brew install sd` | Simpler, faster `sed` replacement for find-and-replace. Supports regex and literal strings with cleaner syntax. |
| **scc** | `brew install scc` | Fast code counter (lines, blanks, comments, complexity). Gives a quick codebase overview without cloning context. |
| **yq** | `brew install yq` | `jq` for YAML, JSON, TOML, and XML. Useful for reading and editing config files in pipelines. |

## Dependencies

- `jq` — JSON parsing in statusline
- `delta` — diff renderer (uses your git config theme automatically)
- `tmux` — required for popup features
- Nerd Fonts — required for all icons in the statusline

## File Structure

```
~/.config/claude/
├── settings.json                   # theme, vim mode, statusline, hooks
├── statusline.sh                   # custom status bar script
├── hooks/                          # hook scripts
└── memory/                         # persistent memory across sessions
```
