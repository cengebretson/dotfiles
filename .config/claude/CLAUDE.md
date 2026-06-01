# Global Claude Instructions

## Session Startup

At the start of every session, run `/health-check` automatically before responding to the first user message. Report the results as a table (GitHub MCP, Jira MCP, context-mode, SSH agent). If anything is red, surface it immediately so it can be fixed before it blocks work.

## Environment

- **Shell:** Fish (interactive), but all scripts must use `#!/usr/bin/env bash` — hooks and non-interactive contexts run bash
- **Editor:** nvim
- **Terminal:** Ghostty + tmux
- **Color scheme:** Catppuccin Mocha throughout (tmux, delta, statusline, starship)

## Claude Config

- Canonical config directory: `~/.config/claude/` — `~/.claude` is a symlink to it
- Global skills: `~/.config/claude/skills/<skill-name>/SKILL.md`
- Project memories: `~/.config/claude/projects/<project-slug>/memory/`
- `CLAUDE_CONFIG_DIR=~/.config/claude` is set in fish config — all sessions (terminal and desktop app) resolve to the same location via the symlink

## Dotfiles Git

Config files are tracked in a bare git repo. Always use these flags for dotfiles git operations:

```bash
git --git-dir=/Users/chris/.dotfiles --work-tree=/Users/chris <command>
```

`dots` is a fish **abbreviation** — it expands inline when typing in the terminal but is not a real command. Always use the full `git --git-dir=...` form in scripts, tool calls, and non-interactive contexts. Paths in the index are relative to `~` (e.g. `.config/tmux/tmux.conf`). Run git commands from `~` to get full paths, or from `~/.config` where paths appear without the `.config/` prefix.

## Tmux

- tmux 3.6 — `display-popup` height percentages (`-h 10%`) do not render; use fixed line counts (`-h 3`) instead
- Width percentages (`-w 40%`) work fine

## context-mode

context-mode is installed globally and active in every session. It keeps large tool outputs out of the context window and captures session state for resumption.

- `/ctx-stats` — show how much context was saved this session
- `/ctx-upgrade` — update to the latest version (check after `/health-check` flags an update)
- `/context-mode:ctx-search` — search prior session captures
- On `/compact` or `/resume`, context-mode preserves the knowledge base automatically

## SSH

Active key: `~/.ssh/chris` (RSA 2048). Load it with:

```bash
ssh-add --apple-use-keychain
```

If the agent has no identities at session start, the `/health-check` skill will surface it.

## GitHub Operations

- **Always prefer `mcp__github__*` tools** for all GitHub interactions (PRs, issues, comments, search, file contents, etc.).
- Fall back to `gh` CLI only when MCP tools are unavailable (headless CI, cron agents) or when shell-level composability is genuinely required (e.g. piping output into another command).

## Memory System

Project memories live at `~/.config/claude/projects/<project-slug>/memory/`. Each project has a `MEMORY.md` index and individual memory files organized by type (user, feedback, project, reference). Memories persist across sessions and inform future conversation context.

## AI-Helpful CLI Tools

These tools are installed and available. Prefer them over naive alternatives when they're a better fit.

| Tool | Use instead of | When to use |
|------|---------------|-------------|
| `ast-grep` | `grep` / regex | Searching or rewriting code by structure — find all function calls, rename a pattern across files, match syntax not strings |
| `difftastic` | `git diff` | Reviewing structural diffs where line-based diffs are noisy — refactors, formatting changes |
| `shellcheck` | manual review | Validating any shell script before finishing — catches bugs, bad practices, portability issues |
| `sd` | `sed` | Find-and-replace in files — cleaner syntax, supports regex and literal strings |
| `scc` | `wc -l` | Getting a codebase overview — lines, blanks, comments, complexity per language |
| `yq` | manual editing | Reading or editing YAML, TOML, JSON config files in pipelines |
| `jq` | manual parsing | Parsing and transforming JSON |
| `delta` | `diff` | Rendering git diffs with syntax highlighting |
| `fd` | `find` | Fast file search with simpler syntax |
| `rg` (ripgrep) | `grep` | Fast recursive text search |
| `bat` | `cat` | Viewing files with syntax highlighting |
| `eza` | `ls` | Directory listings with icons and git status |
