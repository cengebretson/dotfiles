# Codex-Specific Instructions

Added to every Codex session by the `local-instructions` SessionStart hook, after the shared
`~/.config/agents/AGENTS.md`. Keep this file portable; work-machine rules belong in the
gitignored `~/.config/agents/local.md` (shared with Claude) or `~/.config/codex/local.md`
(Codex only).

- Invoke skills with `$name`: `$health-check` at the start of substantive work, and `$fast-loop` for a quick coding handoff or resume.
- Keep persistent `prefix_rule` approvals narrow and task-shaped. Do not request persistent approval for broad shells, interpreters, package managers, or destructive commands. Do not request escalation solely for local, read-only searches.
- Use `~/.config/codex/config.shared.toml` as the portable reference for Codex settings and ask before copying shared settings into the live `config.toml`.
