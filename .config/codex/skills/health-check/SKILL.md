---
name: health-check
description: Run a session health check across critical Codex integrations and local SSH status. Use when the user invokes $health-check, asks for /health-check, or asks for a health check, session check, startup check, or integration check before work begins.
---

# Health Check

Run a compact session health check and report one status line per service. Use available MCP/app/plugin tools when present; skip optional integrations that are not available instead of treating them as failures.

## Checks

### GitHub

Check whether a GitHub MCP/app/plugin tool is available.

- Use tool discovery when available to look for GitHub account/profile tools such as `get_me`, `viewer`, or user-info equivalents.
- If a suitable tool exists, call it and report the authenticated username on success.
- If no GitHub tool exists in the current session, report skipped, not failed.
- Do not use `gh` as a fallback unless the user explicitly asks for a CLI-based check.

### Jira / Atlassian

This check is optional.

- Use tool discovery when available to look for Atlassian/Jira user-info tools.
- If a suitable tool exists, call it and report the authenticated email or username on success.
- If no Atlassian/Jira tool exists, report skipped, not failed.

### context-mode

Check whether context-mode is available.

- Use tool discovery when available to look for context-mode tools such as `ctx_stats`.
- If available, call the stats tool and report the version plus any upgrade notice.
- If unavailable, check installed Codex plugins with `codex plugin list` when appropriate and report not installed/skipped if absent.

### SSH Agent

Run:

```bash
ssh-add -l
```

Interpretation:

- Keys listed: pass; show key count.
- "The agent has no identities": fail; suggest `ssh-add --apple-use-keychain`.
- Agent not running: fail; suggest starting the agent, for Fish usually `eval (ssh-agent -c)`.

## Output

Report only real health-check results. Do not include examples, raw tool output, verbose diagnostics, or explanatory summaries unless the user explicitly asks for details.

Report one service per line. No heading, no summary, no table borders.

Use compact status icons:

- `✅` for passing checks
- `⏭️` for skipped optional integrations
- `❌` for failing checks

Use these forms:

```text
✅ GitHub MCP · username
✅ Jira MCP · you@example.com
✅ context-mode · v1.0.162
✅ SSH · 1 key
⏭️ Jira MCP · not installed
❌ SSH · run: ssh-add --apple-use-keychain
```

If a service fails, include the action item on the same line after `run:` or `fix:`.
