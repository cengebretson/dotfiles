# Health Check

Run a session health check: delegate the static environment audit to `doctor ai`, probe the session-scoped surfaces live, and report results in a single table.

## Trigger

Use when the user runs `/health-check` or asks for a "health check" or "session check".

## Instructions

Run the checks below (Jira is optional), parallelizing independent calls, then report results as one markdown table.

### 1. Static environment audit — `doctor ai`

Run `~/.local/bin/doctor ai` (read-only). It owns the static checks — dependencies, `gh` auth, plugins, hook plumbing (dispatcher and `hooks/handlers/`), config syntax, and skills parity — so do not re-check any of those individually here. Surface every failing or warning line it prints; if everything passes, report a single all-green row.

### 2. Session probes

These must be probed live from inside the running session; `doctor ai` cannot see them from outside.

- **GitHub MCP**: call `mcp__github__get_me`. Report the authenticated username on success.
- **Jira / Atlassian MCP (optional)**: only applies when the Atlassian MCP is installed. First check whether `mcp__claude_ai_Atlassian__atlassianUserInfo` is available (use ToolSearch if it is deferred). If the tool does not exist in this session, report it as skipped — not as a failure. If it exists, call it and report the authenticated email.
- **context-mode**: call `mcp__plugin_context-mode_context-mode__ctx_stats`. Report the version. If an upgrade is available, note it with the version and suggest `/ctx-upgrade`.
- **SSH agent**: run `ssh-add -l`.
  - Keys listed → PASS, show key count.
  - "The agent has no identities" → FAIL. The user loads the key themselves interactively (a passphrase prompt cannot be answered from a tool shell): suggest `! ssh-add --apple-use-keychain`.
  - ssh-agent not running → FAIL, suggest `eval (ssh-agent -c)`.

## Output Format

Report a single markdown table with columns Area, Status, Detail — one row each for repository tools, issue-tracker tools, context-mode, SSH agent, and the doctor-ai findings:

```markdown
| Area | Status | Detail |
|---|---|---|
| Repository tools (GitHub MCP) | ✅ | authenticated as your-gh-username |
| Issue-tracker tools (Jira MCP) | ✅ | you@example.com |
| context-mode | ✅ | v1.0.162 |
| SSH agent | ✅ | 1 key loaded |
| doctor ai | ✅ | all static checks pass |
```

- On failure, put the remediation in the Detail cell (e.g. `run: ! ssh-add --apple-use-keychain`).
- If the Jira MCP is not installed, use `⏭️` with `not installed (skipped)`.
- If `doctor ai` reported failures or warnings, add one row per failing section with its detail instead of the all-green row.
- Keep it concise: no trailing summary beyond the table, except a one-line blocker note when something is red.
