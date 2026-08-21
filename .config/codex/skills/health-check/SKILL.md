---
name: health-check
description: "Verify the portable startup dependencies for Codex: context-mode and GitHub access through `gh`, plus Jira access through `acli` when it is installed. Use at the start of a substantive session or when the user asks for a health check, startup check, tool check, or environment verification. Run the broader machine audit only for an explicitly requested deep check or to diagnose a failed required probe."
---

# Health Check

Run the fast path before substantive work. Keep it small: verify the two
portable dependencies plus optional Jira access and report one row per service.

## Fast Path

Run the independent probes in parallel.

### context-mode

- Discover `ctx_doctor` if it is deferred, then call it.
- Pass when the tool responds and reports no failing checks. Report its version.
- Surface only warnings that affect normal use; do not turn harmless discovery
  metadata into a blocker.
- If the tool is missing or fails, suggest restarting the client and running the
  full context-mode doctor.

### Jira through `acli`

First check whether `acli` is installed:

```bash
command -v acli
```

- If it is absent, report Jira as optional and skipped. This is not a startup
  failure and does not trigger the deep path.
- If it is present, run this read-only live API probe:

```bash
acli jira workitem search --jql "assignee = currentUser()" --count
```

- Pass on exit code 0. The count itself does not matter.
- On failure, run `acli jira auth status` for diagnosis.
- If unauthenticated, suggest `acli jira auth login --web`.
- Do not substitute the Atlassian MCP/plugin for this check; routine Jira work
  uses the machine OAuth profile through `acli`.

### GitHub through `gh`

Run this read-only live API probe:

```bash
gh api user --jq .login
```

- Pass on exit code 0 and report the login.
- On failure, run `gh auth status` for diagnosis.
- If credentials look invalid, check only whether `GH_TOKEN` or `GITHUB_TOKEN`
  is present; never print either value. A stale environment override can mask a
  healthy keyring login, so advise unsetting the override and restarting the
  client before re-authenticating.
- If no override is involved and authentication is invalid, suggest
  `gh auth login --web --git-protocol https`.

## Sandbox Failures

If an installed `acli` or `gh` probe fails because network or keychain access is
sandboxed, retry that exact read-only probe with narrow escalation before
reporting it broken. If escalation is unavailable, report `sandbox-limited`,
not a confirmed host failure.

## Deep Path

Run a deep check only when the user asks for `deep`, `full`, or `debug`, or when
a failed required probe or installed `acli` needs broader diagnosis. Add only
the relevant checks from:

- `~/.local/bin/doctor ai`
- repository status and latest commit
- SSH agent
- Docker
- plugin, hook, and config diagnostics

Do not include these in the normal startup check.

## Output

Return only this compact table, plus one blocker sentence when a row is red:

```markdown
| Dependency | Status | Detail |
|---|---|---|
| context-mode | ✅ | healthy, vX.Y.Z |
| Jira (`acli`) | ➖ | optional; not installed on this machine |
| GitHub (`gh`) | ✅ | authenticated as username |
```

Use `✅` for healthy, `❌` for a confirmed failure, `⚠️` for degraded or
sandbox-limited, and `➖` for an optional skipped probe. Never print secrets or
token values.
