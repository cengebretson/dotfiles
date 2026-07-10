---
name: health-check
description: Run a fast, pretty startup health check at the start of a Codex session or when the user asks for "health check", "$health-check", "startup check", "check tools", or "verify environment". Delegates the static environment audit (dependencies, gh auth, plugins, hooks, config syntax, skills parity) to `doctor ai` and live-probes session-scoped surfaces - repository state, context-mode, GitHub MCP/app auth, Jira MCP, and SSH agent.
---

# Health Check

Run this at the start of a new session before substantive work, or whenever the
user asks for a health check. Default to the fast path. The fast path still performs lightweight plugin discovery for context-mode and GitHub MCP/app surfaces before reporting them unavailable. Use the deep path only
when the user asks for "deep", "full", "debug", or when a fast check fails and the extra detail changes the next action.

When the user asks for a quick coding loop, resume, or `$fast-loop` rather than
a health check, do not run remote auth probes from this skill. Let `$fast-loop`
orient locally first, then run the relevant GitHub, Jira, Slack, or other remote
probe only if the next action needs that surface.

## Fast Path

Run these checks, parallelizing independent shell commands when possible.

### 1. Static environment audit — `doctor ai`

Run `~/.local/bin/doctor ai` (read-only). It owns the static checks — dependencies, `gh` auth, plugins, hook plumbing (dispatcher and `hooks/handlers/`), config syntax, and skills parity — so do not re-check any of those individually here (no `command -v` sweeps, no `gh auth status`, no `acli jira auth status`, no Docker daemon probe). Surface every failing or warning line it prints; if everything passes, report a single all-green row.

### 2. Session probes

These must be probed live from inside the running session; `doctor ai` cannot see them from outside.

- **Repo**: `git rev-parse --show-toplevel`, `git status --short --branch`, and `git log -1 --format=%h%x09%D%x09%s`.
- **GitHub MCP/app**: if no GitHub MCP/app tool is already available, call `tool_search` for GitHub tools, then run a minimal authenticated-user probe when discovered. Report the authenticated username on success.
- **Jira / Atlassian MCP (optional)**: only applies when a Jira/Atlassian MCP tool is available (discover via `tool_search` if deferred). If none exists in this session, report it as skipped — not as a failure. If it exists, run its authenticated-user probe and report the authenticated email.
- **context-mode**: if `ctx_doctor` is not already available, call `tool_search` for context-mode tools, then run `ctx_doctor` when discovered. Report the version. If an upgrade is available, note it with the version.
- **SSH agent**: run `ssh-add -l`.
  - Keys listed → PASS, show key count.
  - "The agent has no identities" → FAIL. The user loads the key themselves interactively (a passphrase prompt cannot be answered from a tool shell): suggest `! ssh-add --apple-use-keychain`.
  - ssh-agent not running → FAIL, suggest `eval (ssh-agent -c)`.

## Coding-Loop Path

Use this only when a coding loop asks for health context indirectly and a full
startup health check has already been satisfied in the session:

- Repo: `git status --short --branch` and `git log -1 --format=%h%x09%D%x09%s`.
- Core tools: `command -v rg git make`.
- context-mode: run `ctx_doctor` only if context-mode tools are already loaded
  or if the next step will process potentially large output.
- Docker: check Docker only when the repo's normal commands need Docker.

Do not check GitHub, Jira, Slack, SSH agent, or other remote/auth surfaces in
the coding-loop path unless the next action needs them.

## Deep Path

For a deep/full/debug health check, also run:

- Additional capability discovery for task-specific MCPs requested by the user or implied by the work, such as Slack, Datadog, or Sentry.
- Expanded MCP diagnostics only when a fast-path probe fails or returns an ambiguous authentication/authorization error.
- Docker daemon detail (`docker version`) only when the upcoming work needs Docker or the user asks for it.

## Sandbox-Sensitive Checks

`ssh-add -l` and `~/.local/bin/doctor ai` may fail inside the Codex sandbox even
when the host shell is healthy. If either fails with permission, keychain,
socket, or token-looking errors, rerun the same check with escalated
permissions before reporting a failure.

If escalation is unavailable or denied, report the check as `⚠️ Sandbox-limited`,
not broken.

## Output Style

Report a single markdown table with columns Area, Status, Detail — one row for the repo, one each for repository tools, issue-tracker tools, context-mode, SSH agent, and the doctor-ai findings. Status markers:

- `✅` healthy
- `❌` confirmed broken outside the sandbox
- `⚠️` unavailable, degraded, or sandbox-limited

```markdown
**Health Check**

| Area | Status | Detail |
|---|---|---|
| Repo | ✅ | clean on `branch-name`, last commit `abc1234` |
| Repository tools (GitHub MCP) | ✅ | authenticated as your-gh-username |
| Issue-tracker tools (Jira MCP) | ✅ | you@example.com |
| context-mode | ✅ | healthy, vX.Y.Z |
| SSH agent | ✅ | 1 key loaded |
| doctor ai | ✅ | all static checks pass |
```

- On failure, put the remediation in the Detail cell (e.g. `run: ! ssh-add --apple-use-keychain`).
- If the Jira MCP is not installed, use `⏭️` with `not installed (skipped)`.
- If `doctor ai` reported failures or warnings, add one row per failing section with its detail instead of the all-green row.
- Keep it concise: no trailing summary beyond the table, except a one-line blocker note when something is red.

## Reporting Rules

- Keep the final report short enough to scan.
- Redact all token values, secrets, credentials, private keys, URLs with embedded credentials, and env var values.
- Distinguish confirmed host failures from sandbox false negatives.
- Mention unrelated dirty work only as repo status, never alter or revert it.
- Do not report context-mode or GitHub MCP/app as skipped merely because tools were lazy-loaded; discover them first.
- If a check is not applicable in the current task after discovery, report it as `⚠️ Not loaded` or omit it if the user asked for a narrower check.
