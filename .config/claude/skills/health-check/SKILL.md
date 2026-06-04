# Health Check

Run a session health check across all critical integrations and report status.

## Trigger

Use when the user runs `/health-check` or asks for a "health check" or "session check".

## Instructions

Run all four checks, then report results in a single markdown table.

### 1. GitHub MCP
Call `mcp__github__get_me`. Report the authenticated username on success.

### 2. Jira / Atlassian MCP
Call `mcp__claude_ai_Atlassian__atlassianUserInfo`. Report the authenticated email on success.

### 3. context-mode
Call `mcp__plugin_context-mode_context-mode__ctx_stats`. Report the version on success.
- If an upgrade is available, note it with the version and suggest `/ctx-upgrade`.

### 4. SSH key agent
Run `ssh-add -l`.
- If keys are listed → PASS, show key count.
- If output is "The agent has no identities" → FAIL, suggest: `ssh-add --apple-use-keychain`
- If ssh-agent is not running → FAIL, suggest: `eval (ssh-agent -c)`

## Output Format

Report as a table followed by any action items:

```
| Service | Status | Detail |
|---|---|---|
| GitHub MCP | ✅ | cengebretson |
| Jira MCP | ✅ | cengebretson@lenderscooperative.com |
| context-mode | ✅ | v1.0.162 |
| SSH agent | ✅ | 1 key(s) loaded |
```

If anything failed, list action items below the table. Keep it concise — one line per item.
