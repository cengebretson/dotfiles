# Health Check

Run a session health check across all critical integrations and report status.

## Trigger

Use when the user runs `/health-check` or asks for a "health check" or "session check".

## Instructions

Run the checks below (Jira is optional), then report results in a single markdown table.

### 1. GitHub MCP
Call `mcp__plugin_github_github__get_me`. Report the authenticated username on success.

### 2. Jira / Atlassian MCP (optional)
This check only applies when the Atlassian MCP is installed. First check whether `mcp__claude_ai_Atlassian__atlassianUserInfo` is available (use ToolSearch if it is deferred). If the tool does not exist in this session, skip the check and report it as skipped — not as a failure. If it exists, call it and report the authenticated email on success.

### 3. context-mode
Call `mcp__plugin_context-mode_context-mode__ctx_stats`. Report the version on success.
- If an upgrade is available, note it with the version and suggest `/ctx-upgrade`.

### 4. SSH key agent
Run `ssh-add -l`.
- If keys are listed → PASS, show key count.
- If output is "The agent has no identities" → FAIL, suggest: `ssh-add --apple-use-keychain`
- If ssh-agent is not running → FAIL, suggest: `eval (ssh-agent -c)`

## Output Format

Report one service per line, no table borders:

```
✅ GitHub MCP · your-gh-username
✅ Jira MCP · you@example.com
✅ context-mode · v1.0.162
✅ SSH · 1 key
```

If a service failed, append the action item on its own line immediately after:
```
❌ SSH · run: ssh-add --apple-use-keychain
```

If the Jira MCP is not installed, report it as skipped rather than failed:
```
⏭️ Jira MCP · not installed (skipped)
```

No headers, no table, no trailing summary.
