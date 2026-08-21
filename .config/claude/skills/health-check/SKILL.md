# Health Check

Verify the portable startup dependencies: context-mode and GitHub through `gh`,
plus Jira through `acli` when it is installed.

## Trigger

Use when the user runs `/health-check`, asks for a health or startup check, or
when first starting substantive work in a repo this session.

## Fast Path

Run the independent probes in parallel. Do not run the general machine audit,
repo status, SSH, Docker, or MCP connector checks by default.

### context-mode

- Find `ctx_doctor` with ToolSearch if necessary, then call it.
- Pass when it responds with no failing checks and report the version.
- Surface only warnings that affect normal use.
- If missing or failing, suggest restarting Claude and running the full
  context-mode doctor.

### Jira through `acli`

First run `command -v acli`.

- If it is absent, report Jira as optional and skipped. Do not treat this as a
  startup failure or trigger the deep path.
- If it is present, run:

```bash
acli jira workitem search --jql "assignee = currentUser()" --count
```

- Pass on exit code 0; the count itself does not matter.
- On failure, run `acli jira auth status`.
- If unauthenticated, suggest `acli jira auth login --web`.
- Do not substitute the Atlassian MCP/plugin for this check.

### GitHub through `gh`

Run:

```bash
gh api user --jq .login
```

- Pass on exit code 0 and report the login.
- On failure, run `gh auth status`.
- If credentials look invalid, check only whether `GH_TOKEN` or `GITHUB_TOKEN`
  is present; never print either value. Advise unsetting a stale override and
  restarting Claude before re-authenticating.
- If no override is involved, suggest
  `gh auth login --web --git-protocol https`.

## Deep Path

Only when the user asks for `deep`, `full`, or `debug`, or a failed required
probe or installed `acli` needs broader diagnosis, add the relevant checks from
`doctor ai`, repo status, SSH, Docker, plugins, hooks, and config.

## Output

Return only this table, plus one blocker sentence when a row is red:

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
