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

Report as a compact inline list — one line per service, no table borders:

```
GitHub MCP ✅ · Jira MCP ✅ · context-mode ✅ v1.0.162 · SSH ✅ 1 key
```

If anything failed, append a short action item on the next line:
```
SSH ❌ — run: ssh-add --apple-use-keychain
```

Keep it to two lines maximum total. No headers, no table, no trailing summary.
