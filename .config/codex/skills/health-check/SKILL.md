---
name: health-check
description: Run a fast, pretty startup health check at the start of a Codex session or when the user asks for "health check", "$health-check", "startup check", "check tools", or "verify environment". Covers repository state, GitHub CLI auth, Jira/Atlassian MCP auth, context-mode, GitHub MCP/app auth, SSH agent, Docker, and core local tools.
---

# Health Check

Run this at the start of a new session before substantive work, or whenever the
user asks for a health check. Default to the fast path. The fast path still performs lightweight plugin discovery for context-mode, Jira/Atlassian, and GitHub MCP/app surfaces before reporting them unavailable. Use the deep path only
when the user asks for "deep", "full", "debug", or when a fast check fails and the extra detail changes the next action.

## Fast Path

Run these checks, parallelizing independent shell commands when possible:

- Repo: `git rev-parse --show-toplevel`, `git status --short --branch`, and `git log -1 --format=%h%x09%D%x09%s`.
- Core tools: `command -v rg git make docker gh ssh-add`.
- context-mode: if `ctx_doctor` is not already available, call `tool_search` for context-mode tools, then run `ctx_doctor` when discovered.
- Jira/Atlassian MCP: if no Atlassian tool is already available, call `tool_search` for Atlassian/Jira tools, then run a minimal current-user probe when discovered.
- GitHub CLI auth: `gh auth status`.
- GitHub MCP/app: if no GitHub MCP/app tool is already available, call `tool_search` for GitHub tools, then run a minimal authenticated-user probe when discovered.
- SSH agent: `ssh-add -l`.
- Docker: `docker version --format '{{.Client.Version}} client / {{.Server.Version}} server'`.

## Deep Path

For a deep/full/debug health check, also run:

- Additional capability discovery for task-specific MCPs requested by the user or implied by the work, such as Slack, Datadog, or Sentry.
- Expanded MCP diagnostics only when a fast-path probe fails or returns an ambiguous authentication/authorization error.
- Full `docker version` only when the terse Docker probe fails or the user asks
  for Docker detail.

## Sandbox-Sensitive Checks

`gh auth status`, `ssh-add -l`, and Docker daemon checks may fail inside the
Codex sandbox even when the host shell is healthy. If any fail with permission,
keychain, socket, or token-looking errors, rerun the same check with escalated
permissions before reporting a failure.

The approved global commands are expected to include:

- `gh auth status`
- `ssh-add -l`
- `docker version`
- `docker version --format '{{.Client.Version}} client / {{.Server.Version}} server'`

If escalation is unavailable or denied, report the check as `⚠️ Sandbox-limited`,
not broken.

## Output Style

Return a compact, pretty checklist. Use these status markers:

- `✅` healthy
- `❌` confirmed broken outside the sandbox
- `⚠️` unavailable, degraded, or sandbox-limited

Use this shape:

```markdown
**Health Check**
✅ Repo: clean on `branch-name`, last commit `abc1234`
✅ Core tools: `rg`, `git`, `make`, `docker`, `gh`, `ssh-add`
✅ context-mode: healthy, vX.Y.Z
✅ Jira MCP: authenticated as Name
✅ GitHub CLI: authenticated as user
✅ SSH agent: 1 key loaded
✅ Docker: client and daemon reachable

No blockers.
```

When there are problems, keep them concrete:

```markdown
**Health Check**
✅ Repo: clean on `feature/foo`
✅ GitHub CLI: authenticated as `cengebretson`
❌ Docker: daemon unreachable outside sandbox, OrbStack socket missing

**Blockers**
❌ Docker-backed tests will fail until OrbStack/Docker is running.
```

## Reporting Rules

- Keep the final report short enough to scan.
- Redact all token values, secrets, credentials, private keys, URLs with embedded credentials, and env var values.
- Distinguish confirmed host failures from sandbox false negatives.
- Mention unrelated dirty work only as repo status, never alter or revert it.
- Do not report context-mode, Jira/Atlassian MCP, or GitHub MCP/app as skipped merely because tools were lazy-loaded; discover them first.
- If a check is not applicable in the current task after discovery, report it as `⚠️ Not loaded` or omit it if the user asked for a narrower check.
