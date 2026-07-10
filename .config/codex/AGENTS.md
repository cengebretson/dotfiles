# Global Codex Instructions

> Machine setup, bootstrap, and how to add MCP servers / hooks / profiles live in
> `../AI-SETUP.md` (the cross-tool runbook for Claude + Codex) — not here. This file is
> behavior only.

## Working Style

- At the start of a new session, use `$health-check` before substantive repo, GitHub, Jira, Docker, or MCP work and report the result. For tiny local-machine questions, use a local-only check instead and say what was skipped.
- For a quick coding handoff or resume, use `$fast-loop` to gather only the repo status, nearest instructions, obvious local task context, and command entrypoints before choosing the next action.
- For familiar implementation work, start from the nearest relevant instructions and task files; defer broad architecture docs, full rulebooks, and remote lookups until the touched files or user request make them relevant.
- Bias toward action. When the next step is obvious and already within the user's request, do it and report what happened.
- Pause for genuinely consequential or ambiguous decisions: destructive actions, broad permission changes, public publishing, or choices where the user's answer changes the outcome.
- Keep responses direct, pragmatic, and concise. Prefer concrete file paths, commands, and verification results over general explanation.
- Do not add AI attribution, "Generated with..." footers, or `Co-Authored-By` lines to commits or PR text.

## Tool Selection

- Prefer MCP/app/plugin tools over raw CLI or REST when an available tool covers the operation.
- For Jira work, prefer Atlassian CLI `acli` over the Atlassian Rovo MCP/plugin. `acli` is authenticated through the machine OAuth profile and supports useful comment operations such as list, create, update, and delete. Use MCP only when explicitly requested or when `acli` cannot cover the operation.
- For structured Jira output, prefer `los-scripts jira` (`~/workspace/scripts/bin/los-scripts`) — it wraps `acli` and emits compact agent-parseable JSON on stdout (`view`, `epic-children`, `comments`, `comment-add`, `transition`, `link`). Fall back to raw `acli` when a needed operation is not wrapped.
- For GitHub work, check for a GitHub MCP/app tool before using `gh` or `curl`. If no suitable tool is available or the tool fails, say that you are falling back to CLI before using it.
- Use `rg` for text search and `rg --files` for file search before slower alternatives.
- When searching local Codex, tmux, or Fish config, exclude generated caches and sessions such as `~/.config/codex/plugins/cache`, `~/.config/codex/sessions`, `~/.config/codex/context-mode`, and `~/.config/codex/.tmp` unless the task is specifically about those files.
- Prefer structured tools/parsers for structured data. Use `jq` for JSON and `yq` for YAML/TOML/JSON when appropriate.
- Prefer installed higher-signal CLI tools when they fit:
  - `ast-grep` for syntax-aware code search or rewrites.
  - `difftastic` for structural diffs.
  - `shellcheck` for shell scripts.
  - `sd` for simple find-and-replace.
  - `scc` for codebase line/complexity overviews.
  - `fd` for ergonomic file search.
  - `bat`, `eza`, and `glow` for human-facing display when useful.

## Permission Hygiene

- When requesting a persistent command approval, keep `prefix_rule` narrow and task-shaped, such as `["make", "test"]` or `["gh", "pr", "view"]`.
- For routine Jira CLI work, prefer narrow `acli` approval prefixes such as `["acli", "jira", "auth", "status"]`, `["acli", "jira", "workitem", "view"]`, `["acli", "jira", "workitem", "search"]`, or `["acli", "jira", "workitem", "comment", "list"]`; request mutating prefixes like `comment create/update/delete`, `workitem edit`, or `transition` only when the task needs them.
- Do not request broad persistent approvals for shells, interpreters, package managers, or generic CLIs unless the exact subcommand is constrained enough to be safe.
- Prefer one-off approval for unusual writes, destructive actions, broad environment changes, or commands that combine several operations.
- If an approval rule was clearly a one-off workaround, do not reuse it as evidence that similar future commands should be allowed.
- Read-only tmux probes such as `tmux show-options`, `tmux show-window-options`, and `tmux display-message` are safe candidates for narrow persistent approval when debugging terminal behavior.
- On this macOS setup, Docker may use the OrbStack socket at `~/.orbstack/run/docker.sock`, which can fail inside the Codex sandbox with a socket permission error. Treat that as sandbox friction, not an app failure. For container inspection or Django shell work, rerun the needed command with explicit approval and the narrow persistent prefix `["docker", "exec"]`.
- On macOS, browser or GUI automation can fail inside the Codex `workspace-write` sandbox because the app process needs OS services outside the file sandbox. Do not switch the whole session to `danger-full-access` for this. Keep normal work sandboxed, then rerun only the browser or GUI command with explicit approval using a narrow, task-shaped `prefix_rule`, such as `["npx", "playwright", "test"]`, `["npm", "test"]`, `["npm", "run", "test:all"]`, or `["npm", "run", "test:ticket"]`.
- For scratch files, temporary scripts, generated logs, or one-off artifacts that do not belong in the repo, write under `/tmp` or `/private/tmp` rather than inside project directories or home-directory caches.

## Environment

- Interactive shell preference: Fish.
- Scripts, hooks, and non-interactive commands should use Bash with `#!/usr/bin/env bash` unless the project says otherwise.
- Editor: nvim.
- Terminal: Ghostty + tmux.
- Color scheme preference: Catppuccin Mocha.

## Dotfiles

- Dotfiles are tracked in a bare git repository. Use this form for dotfiles git operations:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" <command>
```

- `dots` is a Fish abbreviation, not a real command. Do not use it in scripts, tool calls, or non-interactive commands.
- The dotfiles repo uses `status.showUntrackedFiles=no`; use `dots-status`, `dots-untracked`, or `git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" status --short --untracked-files=all` before assuming a new file is tracked.
- Machine-local files must not be committed or hardcoded:
  - `~/.config/git/config.local`
  - `~/.config/fish/secrets.fish`
  - `~/.config/claude/.claude.json`
- For Codex settings, keep `~/.config/codex/config.toml` untracked because it contains machine-local trust state, absolute paths, and hook hashes. Use `~/.config/codex/config.shared.toml` as the tracked reference for portable settings, and ask before copying any shared setting into the live `config.toml`.
- The dotfiles setup script makes `~/.codex` a symlink to `~/.config/codex`; treat those paths as the same Codex home. Prefer editing the canonical `~/.config/codex/...` path, and do not make separate divergent changes under `~/.codex/...`.
- If changing Fish config, validate changed Fish files with `fish -n` before finishing.
- Fisher-generated files under `functions/`, `conf.d/`, or `completions/` should not be committed unless they are intentional custom dotfiles.

## Git And Commits

- Never run destructive git commands such as `git reset --hard` or `git checkout --` without explicit user authorization.
- For non-interactive Git operations that may open an editor, use `core.editor=true` or `GIT_EDITOR=true` so rebases and commits do not block on an interactive editor.
- Do not revert user changes unless the user explicitly asks.
- Keep commits focused and authored solely by the user.
- Never add AI attribution to commits, PR descriptions, or generated notes.

## GitHub PR Workflow

- For PR review state, prefer `los-scripts review` (`~/workspace/scripts/bin/los-scripts`) — `status`, `ready`, `comments`, and `checks` return review state, threads, and the checks rollup as JSON on stdout. Prefer it over hand-rolled GraphQL; the guidance below remains the fallback when it does not cover the operation.
- After renaming a branch that backs an open GitHub PR, immediately verify the PR state and head branch. GitHub can close the PR instead of moving the head branch cleanly. If that happens, recreate the PR from the renamed branch and update Jira links.
- For Copilot review requests, use GraphQL `requestReviews` with `botIds`, then verify through `requested_reviewers` or PR events. Do not rely on `gh pr edit --add-reviewer` or REST reviewer shortcuts for Copilot because they can appear successful without starting a bot review.
- For PR review cleanup, a clean later review is not enough. Always query unresolved `reviewThreads`, reply to fixed threads with the commit SHA, resolve them, and re-check unresolved thread count before declaring the PR clean.
- Keep PR label changes on the GitHub app/MCP path when available; use `gh` only when the connector does not expose the needed operation.

## Validation

- Run targeted checks that match the changed files and project conventions.
- If sandboxed commands warn that they cannot write under `~/Library/Caches` for `mise` or Go build cache, prefer adding or using a project-local ignored cache path such as `.cache/mise` and `.cache/go-build` through the repo's Makefile or test wrapper. For one-off commands, rerun with temp cache dirs such as `MISE_CACHE_DIR=/private/tmp/mise-cache GOCACHE=/private/tmp/go-build-cache`. Do not treat cache permission warnings as project failures.
- Validate Lua changes with `luac -p <file>` when working on Neovim/Lua config.
- Validate shell scripts with `shellcheck` when available.
- For Fish files, run `fish -n <file>`.

## Tool Gotchas

- `rg`: `-h` means `--help`, not "no filename". Use `--no-filename` or `-I` for no-filename output.
- If a command unexpectedly prints a tool's help text, assume a bad flag and fix the command before trusting the output.

## context-mode

The context-mode plugin **auto-injects** its full routing guidance (Think-in-Code, the
tool-selection hierarchy, `ctx` commands, session-memory rules) into context at session start via
its hooks — a single source of truth the plugin keeps current and platform-correct, so it is **not**
duplicated here. This relies on `plugin_hooks = true` / `[features].hooks = true` in `config.toml`
(see `../AI-SETUP.md`).

Durable intent if that injected guidance is ever absent: prefer context-mode tools to keep raw bytes
out of context — program the analysis with `ctx_execute`, gather/search with `ctx_batch_execute` and
`ctx_search` instead of reading large raw output into the conversation, and on resume search session
memory before asking the user what you were doing.
