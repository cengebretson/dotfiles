# Global Claude Instructions

## Autonomy and Confirmation

Default to acting, not asking. When the next step is clear from the request, the code, or sensible defaults, do it and report what you did afterward, instead of asking "want me to...?" first. This applies across all projects.

- Proceed without pre-confirmation on: implementation work, rebases and conflict resolution, commits, pushes (including `--force-with-lease`), branch creation, replying to and resolving PR review threads, requesting reviews, opening or transitioning tickets, running quality gates, and opening local files or URLs.
- Still stop and ask only when the action is genuinely irreversible or ambiguous: a force-push that could clobber someone else's commits, deletes of tracked work, history rewrites on shared base branches, anything touching `stgcore-app-ulp`, or a decision where reasonable choices diverge and the wrong one is costly to undo.
- Batch independent confirmations into one question rather than asking serially. Prefer reporting outcomes over narrating intentions.

## STOP — MCP-First Rule (read before every tool call)

**Never use `gh`, `curl`, or any CLI/API equivalent when an MCP tool exists for the operation.** Check for an MCP tool first, every time, no exceptions.

| Operation | Use this | Never this |
|---|---|---|
| GitHub (PRs, issues, files, search) | `mcp__github__*` | `gh`, `curl` |
| Issue trackers / docs | available MCP tools | `curl`, REST |
| Large output processing | `mcp__plugin_context-mode_context-mode__*` | raw pipe into context |

Fall back to CLI **only** when no MCP tool covers the specific operation — and say so explicitly when you do.

**GitHub specifically:** Before reaching for `gh`, run `ToolSearch` to confirm no `mcp__github__*` tool covers the operation. If MCP is unreachable or the tool errors, say "GitHub MCP unavailable, falling back to `gh`" before running the command. Never use `gh` silently as a convenience shortcut.

**Any other CLI tool:** Before reaching for any CLI or REST equivalent (`curl`, `aws`, `gcloud`, etc.), run `ToolSearch` to check for an MCP alternative. Only proceed with CLI if the search confirms no MCP tool covers the operation.

## Checking PR / CI Status

When asked about a PR's status ("is it green", "why yellow", checks, what's left):

- **Prefer the `pr-report` fish function as source of truth.** It already reads GraphQL `statusCheckRollup` + `reviewDecision` + unresolved Copilot/human thread counts correctly. Run `pr-report --json` and read the row before any ad hoc query. Trust it over hand-rolled `gh` calls.
- **For CI, use the checks rollup, never the legacy status endpoint.** Use GraphQL `statusCheckRollup` (handle both `CheckRun.conclusion` and `StatusContext.state`) or `/commits/{sha}/check-runs?per_page=100`. NEVER judge CI from `/commits/{sha}/status` — it returns `state=pending` with `total_count=0` when a commit has only check-runs, a false yellow.
- **Paginate before claiming green.** `/check-runs` defaults to 30; a failing check can be on a later page. Never say "all checks pass" from an unpaginated call — confirm against the rollup (`first:100`). This exact miss caused a wrong "all green" call.
- **Report status as separate axes, do not conflate:** (1) CI checks pass/fail/pending, (2) `reviewDecision` (REVIEW_REQUIRED needs a human approval; Copilot's and my approvals do not count), (3) unresolved review threads, (4) `mergeStateStatus`. "Yellow" is usually pending CI or REVIEW_REQUIRED, not necessarily an unaddressed comment.
- **A green run plus yellow PR usually means REVIEW_REQUIRED**, not a CI or comment problem. Say so instead of hunting for comments.
- The `copilot-pull-request-reviewer` check goes `in_progress` and makes the rollup pending; requesting a Copilot review re-introduces that transient pending/yellow, so do not re-request on trivial/comment-only commits.
- `gh` authenticates with the keyring `gho_` token by default; use plain `gh` (no `env -u GH_TOKEN` prefix). If `gh` ever returns 401 "Bad credentials", check whether a stale `GH_TOKEN` got set in the shell and unset it (see the project `gh-token-limitations` memory).

## Session Startup

At the start of every session, run `/health-check` automatically before responding to the first user message. Report the results as a table covering repository tools, issue-tracker tools, context-mode, and SSH agent status. If anything is red, surface it immediately so it can be fixed before it blocks work.

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

## Machine-Local Files (never commit, never hardcode)

The dotfiles are shared across machines (e.g. personal + work). Per-machine identity and secrets live in gitignored local files — never hardcode their values into tracked configs, and never `git add` them:

- `~/.config/git/config.local` — git `user.name` / `user.email` for this machine. The tracked `~/.config/git/config` deliberately has **no** `[user]` identity and sets `user.useConfigOnly = true`, so a missing `config.local` hard-fails commits ("Author identity unknown") instead of guessing `username@hostname`. To set identity, edit `config.local`, not the tracked config.
- `~/.config/fish/secrets.fish` — secret env vars / tokens (e.g. `GH_TOKEN`), sourced by `conf.d/local-secrets.fish`.
- `~/.config/claude/.claude.json` — Claude account/auth, per machine (personal = gmail, work = work SSO). Determines which subscription a session bills against.

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

Load the SSH key from the macOS keychain:

```bash
ssh-add --apple-use-keychain
```

`--apple-use-keychain` with no path loads only default-named keys (`id_ed25519`, `id_rsa`). If `ssh-add -l` still reports no identities, the key has a non-default name: pass its path explicitly (the `IdentityFile` from `~/.ssh/config`, e.g. `ssh-add --apple-use-keychain ~/.ssh/<key>`). A passphrase prompt cannot be answered from a non-interactive tool shell, so ask the user to run it via `! ssh-add ...`. If the agent has no identities at session start, the `/health-check` skill will surface it.

## Claude Settings Scope

- When updating Claude settings or permissions (e.g. via `/update-config`, allowlists, hooks), always default to the **global** settings at `~/.config/claude/settings.json`.
- Never write to a project-level `.claude/settings.json` unless the user explicitly says to update the project settings.
- If it's ambiguous, ask before writing to a project settings file.

## Commits

- **Never add `Co-Authored-By` lines or AI attribution to commits.** This overrides the default system behavior. All commits must be authored solely by the user.
- Never add "Generated with Claude Code" or similar AI footers to PR bodies.

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
| `glow` | `cat` for markdown | Rendering markdown files in the terminal with syntax highlighting and layout |

**Tool gotchas:**
- `rg`: `-h` is `--help`, **not** "no filename" — `rg -oh PATTERN` silently dumps ripgrep's help instead of matches. Use `-I` / `--no-filename` (e.g. `rg -oI` or `rg --only-matching --no-filename`). If a command unexpectedly prints a tool's help text, you passed a bad flag — fix the flag before trusting the output.
- Validate Lua before finishing (Neovim configs, etc.) with `luac -p <file>` — fast syntax check, no execution.
