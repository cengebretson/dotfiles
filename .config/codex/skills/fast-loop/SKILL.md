---
name: fast-loop
description: Quickly orient Codex for a coding session in any repository. Use when the user asks for "$fast-loop", "fast loop", "quick start", "get moving", "resume coding", "what is next", "start the coding loop", or wants a low-friction repo orientation before implementation. Applies generically across repos and delegates to repo-local AGENTS.md, README, Makefile, package scripts, and feature/task artifacts when present.
---

# Fast Loop

Run a minimal, repo-agnostic orientation that gets to the next useful coding step without broad reading or remote calls.

## Workflow

1. Establish location and cleanliness:
   - Run `pwd`, `git rev-parse --show-toplevel`, `git status --short --branch`, and `git log -1 --format=%h%x09%D%x09%s`.
   - If outside a git repo, inspect the current directory lightly and report that normal git context is unavailable.
   - Preserve dirty work. Do not revert, clean, stage, commit, or switch branches unless the user asks.

2. Load only nearest durable guidance:
   - Read the closest applicable `AGENTS.md` or equivalent repo instruction file.
   - If the task path is known and nested guidance exists, read only the nearest nested guidance for that path.
   - Defer large rulebooks, architecture docs, and workflow docs unless the request or touched files make them relevant.

3. Identify task context from local signals:
   - Infer ticket or task keys from the branch name, current path, recent commit, or obvious local task directories.
   - If a `.features/`, `.tasks/`, `docs/`, or similar local planning artifact matches the inferred task, read the smallest likely entrypoint such as `plan.md`, `README.md`, or `status.md`.
   - Do not create or modify task artifacts during orientation.

4. Check project command surface:
   - Inspect the smallest command router available: `Makefile`, `package.json`, `justfile`, `Taskfile.yml`, `pyproject.toml`, `Cargo.toml`, or repo README command section.
   - Prefer existing project commands over ad hoc direct tool commands.
   - Avoid dependency installs, long tests, servers, Docker startup, migrations, and remote API calls unless already requested or clearly needed.

5. Report a compact next-step summary:
   - Current repo, branch, cleanliness, and last commit.
   - Any detected task/ticket and local plan artifact.
   - Relevant command entrypoints.
   - One to three likely next actions, with the recommended first action first.

## Output Shape

Keep the result short:

```markdown
**Fast Loop**
Repo: `<name>` on `<branch>`, `<clean|dirty>`
Task: `<detected task or none>`
Context: `<guidance/artifact read>`
Commands: `<make test>`, `<npm run lint>`, ...

Recommended next step: `<concrete action>`
```

## Boundaries

- Stay generic. Repo-specific behavior belongs in the repo's own guidance or skills.
- Keep output terse and actionable.
- Use context-mode for searches, file analysis, or command output that may exceed 20 lines.
- Do not call GitHub, Jira, Slack, or other remote services during fast-loop orientation unless the user explicitly asks.
- Do not run health checks from this skill unless the user asks for health or the session has not yet satisfied required startup health guidance.
