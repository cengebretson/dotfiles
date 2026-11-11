# Global Claude Instructions

@~/.config/agents/AGENTS.md

## Claude-Specific

- Invoke skills with `/name`, for example `/health-check` at the start of substantive work.
- Claude has no GitHub MCP server configured, so GitHub work goes straight to `gh`.
- This machine's work rules load from `rules/machine-local.md`, a symlink to the gitignored `~/.config/agents/local.md`.
- Machine-local, untracked files may exist on some machines; check for them before assuming a setting or helper is missing:
  - `~/.config/agents/local.md`: work rules, machine-only helper commands and their setup.
  - `~/.config/claude/work-settings.json`: work-only settings (`autoMode` rules, permissions, sandbox paths and hosts). The
    `claude` fish wrapper passes it with `--settings` at launch, so restart after editing it.
  - A user-level `~/.config/claude/settings.local.json` is not loaded by Claude Code; only a project's
    `.claude/settings.local.json` is. Put machine-only settings in `work-settings.json` instead.
- Keep tracked dotfiles generic: usernames, work hosts, repo names and machine-only paths go in those untracked files.
