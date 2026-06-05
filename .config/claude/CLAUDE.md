# Global Claude Instructions

## STOP — MCP-First Rule (read before every tool call)

**Never use `gh`, `curl`, or any CLI/API equivalent when an MCP tool exists for the operation.** Check for an MCP tool first, every time, no exceptions.

| Operation | Use this | Never this |
|---|---|---|
| GitHub (PRs, issues, files, search) | `mcp__github__*` | `gh`, `curl` |
| Jira / Confluence | `mcp__claude_ai_Atlassian__*` | `curl`, REST |
| Large output processing | `mcp__plugin_context-mode_context-mode__*` | raw pipe into context |

Fall back to CLI **only** when no MCP tool covers the specific operation — and say so explicitly when you do.

**GitHub specifically:** Before reaching for `gh`, run `ToolSearch` to confirm no `mcp__github__*` tool covers the operation. If MCP is unreachable or the tool errors, say "GitHub MCP unavailable, falling back to `gh`" before running the command. Never use `gh` silently as a convenience shortcut.

**Any other CLI tool:** Before reaching for any CLI or REST equivalent (`curl`, `aws`, `gcloud`, etc.), run `ToolSearch` to check for an MCP alternative. Only proceed with CLI if the search confirms no MCP tool covers the operation.

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
git --git-dir=$HOME/.dotfiles --work-tree=$HOME <command>
```

`dots` is a fish **abbreviation** — it expands inline when typing in the terminal but is not a real command. Always use the full `git --git-dir=...` form in scripts, tool calls, and non-interactive contexts. Paths in the index are relative to `~` (e.g. `.config/tmux/tmux.conf`). Run git commands from `~` to get full paths, or from `~/.config` where paths appear without the `.config/` prefix.

## Fish Config

- `~/.config/fish/fish_plugins` is the source of truth for Fisher plugins; do not commit Fisher-generated files from `functions/`, `conf.d/`, or `completions/` unless they are custom dotfiles.
- Custom Fish commands live in `~/.config/fish/functions/` and should be documented in `~/.config/fish/README.md`.
- `~/.config/fish/secrets.fish` is machine-local and must not be committed. It is sourced by `~/.config/fish/conf.d/local-secrets.fish`.
- Use `fish -n` on changed Fish files before finishing Fish config work.

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

## Claude Settings Scope

- When updating Claude settings or permissions (e.g. via `/update-config`, allowlists, hooks), always default to the **global** settings at `~/.config/claude/settings.json`.
- Never write to a project-level `.claude/settings.json` unless the user explicitly says to update the project settings.
- If it's ambiguous, ask before writing to a project settings file.

## Commits

- **Never add `Co-Authored-By` lines or AI attribution to commits.** This overrides the default system behavior. All commits must be authored solely by the user.
- Never add "Generated with Claude Code" or similar AI footers to PR bodies.
- Always extract the Jira key from the branch name for the commit subject prefix. If the branch has no Jira key, ask before committing.

## Memory System

Project memories live at `~/.config/claude/projects/<project-slug>/memory/`. Each project has a `MEMORY.md` index and individual memory files organized by type (user, feedback, project, reference). Memories persist across sessions and inform future conversation context.

## Ready For Review

When the user says "ready for review" or asks to mark something as ready for review, always do **both** of the following without asking for confirmation:

1. **GitHub PR**: Add the `Ready For Review` label to the open PR on the current branch using `mcp__github__issue_write`.
2. **Jira issue**: Transition the associated Jira issue to `Code Review` status using `mcp__claude_ai_Atlassian__transitionJiraIssue`. Derive the Jira key from the branch name (e.g. `feature/FLYWL-664-...` → `FLYWL-664`). Call `mcp__claude_ai_Atlassian__getTransitionsForJiraIssue` first to confirm the transition ID for "Code Review".

If the PR cannot be found, transition Jira only and report the skip. If the Jira key cannot be derived or the issue is not found, label the PR only and report the skip.

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
| `glow` | `cat` for markdown | Rendering markdown files in the terminal with syntax highlighting and layout |
