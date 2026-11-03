# Global Agent Instructions

> Shared by Claude Code (imported from `~/.config/claude/CLAUDE.md`) and Codex
> (`~/.config/codex/AGENTS.md` is a symlink to this file). Keep it tool-neutral and portable:
> tool-specific rules live in `claude/CLAUDE.md` and `codex/codex.md`, and this machine's work
> rules live in the gitignored `~/.config/agents/local.md`. Machine setup, bootstrap, MCP
> servers, hooks and configuration layout live in `~/.config/AI-SETUP.md`.

## Working Style

- Default to quiet execution: one short sentence per meaningful milestone or required progress update, with no routine tool narration. Do not announce context-mode, ctx_* calls, indexing, or token savings unless asked or a failure needs attention. Continue using the tools needed for the task.
- Keep verbose command output in logs or process it before returning it; show a short result or actionable error excerpt. Do not repeat successful tool output in prose or dump tool code, raw JSON, or full logs into the conversation.
- Default final responses to one short paragraph or at most three short bullets: result, verification, and any remaining blocker. Expand when asked or when a review or explanation requires detail. Always surface failures, necessary approvals, and incomplete work.
- Answer direct questions promptly, and honor runtime-required progress updates with the shortest useful update.

- At the start of substantive work, use the `health-check` skill. Keep the normal check lightweight; run deep diagnostics only when requested or when a required probe fails. For tiny local questions, use local-only checks and say what was skipped.
- For a quick coding handoff or resume, inspect repository status, nearest instructions, obvious task artifacts, and the project command router before choosing the next action.
- For familiar implementation work, start from the nearest relevant instructions and touched files. Load broad architecture or workflow documentation only when the task makes it relevant.
- Bias toward action when the next step is clear and within scope. Pause for destructive actions, broad permission changes, public publishing, or decisions where reasonable choices materially diverge.
- Preserve user changes and unrelated dirty work. Never revert, delete, or rewrite them without explicit authorization.
- When working inside tmux, whenever a Jira key becomes known from the user, Jira, the branch, worktree metadata, or task artifacts, immediately reconcile the current pane's tmux-attention project. Keep automatic context when it matches; otherwise run `tmux-attention project set <KEY> --slug <short-kebab-case-summary>`, then verify it with `tmux-attention get`. Update the declaration when switching tickets and clear it only when the pane returns to non-ticket work. Do not infer Jira keys from window names or arbitrary prompt text. If tmux-attention is unavailable or the session is outside tmux, continue without treating that as a task failure.
- When working inside tmux, keep a 3-5 word summary of the current task on your pane with `tmux-attention summary set <phrase>` (for example `tmux-attention summary set fix PR status cache`). Set it once the task is clear, update it when the task materially changes, and run `tmux-attention summary clear` when the pane returns to idle or unrelated work. Use plain words with no ticket key (the project label already shows it). If tmux-attention is unavailable or the session is outside tmux, skip this without treating it as a failure.

## Tool Routing

- Follow the nearest repository instructions and established command surface. Prefer, in order: a repository helper or skill that encodes workflow safeguards, a suitable app or MCP connector, an authenticated CLI, then raw REST or `curl`.
- Use tool discovery when a connector could materially help and its availability is unknown. Do not run discovery before routine local commands.
- For Jira, prefer `acli` when installed unless repository guidance provides a safer helper. Use MCP when explicitly requested or when the CLI cannot cover the operation.
- For GitHub, use a GitHub MCP connector when this tool has one configured and it covers the operation; otherwise use `gh` directly. If a configured connector fails, say that you are falling back before using `gh`.
- Use `rg` and `rg --files` for text and file search. Prefer structured parsers such as `jq` or `yq` for structured data.
- Use context-mode for large or unpredictable output so raw bytes do not consume the conversation context.

## Permission and Shell Hygiene

- Keep shell commands simple and task-shaped. Run routine commands with the tool's working-directory argument instead of prefixing them with `cd`, and do not wrap them in `bash -lc`, `zsh -lc`, or `sh -c` just to change directory or capture output.
- Do not add shell redirection, assignments, substitutions, or control flow to routine approved commands merely for logging; that makes the approval target the whole shell script. Use tool output limits, context-mode for large output, or the command's native output-file option. Keep helper JSON stdout separate from diagnostic stderr.
- Do not compensate for command-shape problems with broad shell or interpreter allowances, arbitrary-command runner wrappers, or repeated exact-script approvals. Fix command construction first. A skill or user instruction cannot override the active sandbox or approval policy.
- Request narrow persistent approvals for repeatable operations. Use one-off approval for unusual writes, destructive actions, broad environment changes, or compound commands.
- Do not request approval solely for local, read-only searches.
- Keep remote commands and local output filtering separate when that makes the approval target clearer; prefer native filters such as `gh --jq`.
- Write scratch scripts, generated logs, and one-off artifacts under `/tmp` or `/private/tmp`.
- On macOS, keep normal work sandboxed and escalate only the browser or GUI command that requires OS services.

## Environment

- Interactive shell: Fish.
- Shell scripts, hooks, and non-interactive shell commands should use Bash with `#!/usr/bin/env bash` unless the project says otherwise.
- Editor: nvim.
- Terminal: Ghostty with tmux.
- Color scheme preference: Catppuccin Mocha.

## Dotfiles and Config

- Dotfiles use a bare Git repository:
  ```bash
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" <command>
  ```
- `dots` is a Fish abbreviation, not a command. Use the full Git form in scripts and tool calls.
- Because the dotfiles repository hides untracked files by default, explicitly include `--untracked-files=all` or use the local status helpers before assuming a new file is tracked.
- Never commit or hardcode machine-local identity, secrets, auth, or trust state. Important local files include `~/.config/git/config.local`, `~/.config/fish/secrets.fish`, `~/.config/claude/.claude.json`, `~/.config/codex/config.toml`, and `~/.config/agents/local.md`.
- Keep this file and the tool-specific instruction files generic: project names, work repos, internal hosts and work-only helpers belong in `~/.config/agents/local.md`.
- Prefer canonical paths under `~/.config`; `~/.claude` and `~/.codex` resolve there on configured machines.
- When changing Fish files, run `fish -n`. Do not commit generated Fisher files unless they are intentional custom dotfiles.

## Git and Remote Work

- Never run destructive Git commands such as `git reset --hard` or `git checkout --` without explicit authorization.
- For noninteractive Git writes, prefer `git commit -m ...` and `git merge --no-edit ...`. Use `core.editor=true` or `GIT_EDITOR=true` only for operations that can actually open an editor.
- Keep commits focused and authored solely by the user. Never add AI attribution, `Co-Authored-By`, or generated-by footers to commits, PRs, or notes.
- After mutating GitHub, Jira, documentation, or generated agent files, independently read back the changed state before reporting success.
- When reporting PR readiness, separate CI results, review decision, unresolved threads, and merge state. Verify the current head and paginate checks before claiming green.
- After renaming a branch that backs an open PR, verify the PR and head branch immediately.
- For Copilot review requests, use the supported bot-review API path and verify the request. A later clean review does not replace resolving relevant existing review threads.

## Validation

- Run targeted checks that match the changed files and project conventions.
- Validate shell scripts with `shellcheck` when available, Fish with `fish -n`, and Lua with `luac -p`.
- Treat sandbox cache-permission warnings as environment constraints, not project failures. Prefer project-local ignored caches or one-off caches under `/private/tmp`.

## context-mode

context-mode injects its current routing and session-memory guidance automatically. Prefer its gather, processing, and search tools for large outputs, and search preserved session memory before asking the user to reconstruct prior work.
