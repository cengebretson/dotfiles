# AI Tooling Setup

Human runbook for the AI coding agents on this machine (**Claude Code** + **Codex CLI**):
how to bootstrap a fresh clone, how to add things, and how to keep the two in sync.

> This is **not** agent-behavior config. That lives in `claude/CLAUDE.md` and `codex/AGENTS.md`
> (which the agents auto-read every session — keep setup steps *out* of them). This file is for a
> human (or an agent explicitly asked to set up a machine). Component reference for Claude's
> statusline/tools is in `claude/README.md`.

## Source-of-truth map

Everything is tracked in the bare dotfiles repo unless noted gitignored. Run dotfiles git as:

```bash
git --git-dir=$HOME/.dotfiles --work-tree=$HOME <cmd>
```

| Path | Role | Tracked? |
|---|---|---|
| `Brewfile` | dependency manifest (the install list — don't restate it here) | ✅ |
| `claude/` → symlinked from `~/.claude` | Claude config | |
| `claude/settings.json` | live Claude config (allowlist, hooks, plugins, statusline) | ✅ |
| `claude/.claude.json` | account/auth (per machine: personal vs work SSO) | 🚫 gitignored |
| `codex/` → symlinked from `~/.codex` | Codex config | |
| `codex/config.toml` | **live** Codex config (machine-local; Codex also writes managed state here) | 🚫 gitignored |
| `codex/config.shared.toml` | **portable reference** — copy wanted bits into `config.toml` | ✅ |
| `codex/rules/default.rules` | execpolicy allowlist; auto-grows per machine via `auto_review` | 🚫 gitignored |
| `codex/auth.json` | account/auth | 🚫 gitignored |
| `fish/secrets.fish` | secret env vars (`GH_TOKEN`, `GITHUB_PERSONAL_ACCESS_TOKEN`, …) | 🚫 gitignored |
| `git/config.local` | git `user.name`/`user.email` for this machine | 🚫 gitignored |

Rule of thumb for *every* config: **share the reference, never the secret or the machine-specific bit.**

## New-machine bootstrap (manual steps a clone can't capture)

A `git clone` of the dotfiles restores tracked files; these are the steps it can't:

1. **Packages:** `brew bundle --file ~/.config/Brewfile`
   (includes Homebrew `bash` 5.x + `shfmt` + `jq` — required by the Claude compound-bash hook;
   macOS ships bash 3.2, which the hook re-execs away from.)
2. **Secrets (create, never commit):** `fish/secrets.fish`, `git/config.local`, `claude/.claude.json`.
   Without `git/config.local`, commits hard-fail by design (`user.useConfigOnly`).
3. **SSH:** `ssh-add --apple-use-keychain` (add the key path if it has a non-default name).
4. **Logins:**
   - `gh auth` (or set `GH_TOKEN` in `secrets.fish`)
   - Claude Code: sign in (determines which subscription bills)
   - Codex GitHub MCP: either set `GITHUB_PERSONAL_ACCESS_TOKEN` in `secrets.fish` (PAT path),
     or run `codex mcp login github` (OAuth path — no PAT to manage; creds stored encrypted, per machine)
5. **Codex live config:** copy the wanted blocks from `codex/config.shared.toml` into `codex/config.toml`
   (it's a reference, not auto-loaded). At minimum: `[mcp_servers.github]` and the `[profiles.*]`.
6. **Plugins:** enable the same plugins (Claude: `enabledPlugins` in `settings.json` is already tracked,
   so they re-fetch on first run; Codex: marketplace plugins like `context-mode` re-install).
7. **Verify:** `/health-check` (Claude) · `codex doctor` · `~/.config/claude/hooks/dispatch.sh doctor </dev/null`
   (the `</dev/null` matters — the dispatcher reads stdin before its subcommand switch).

## How to add things (with the share-vs-local rule)

**MCP server**
- No secret + generic URL (token via `*_env_var` reference) → **shareable**.
  - Codex: `[mcp_servers.<name>]` in `config.shared.toml` *and* `config.toml`.
  - Claude: enable an official plugin in `settings.json` (preferred when one exists — it bundles
    managed OAuth + upkeep), or add an http server via `.mcp.json`.
- Inline/hardcoded token, local stdio path, or work-only → **`config.toml` only** (gitignored).

**Hook**
- Claude: drop the script in `claude/hooks/`. If it's a *side-effect* hook (notify/format), route it
  through `dispatch.sh` (it swallows stdout + always exits 0). If it must return a **decision**
  (e.g. a `PreToolUse` permission hook), register it **directly** — `dispatch.sh` would discard the
  stdout the decision rides on. Add a matching `dispatch.sh doctor` check for its deps.
- Codex: `hooks.json` (synchronous shell command, JSON on stdin → JSON on stdout).

**Codex profile** — add `[profiles.<name>]` to `config.shared.toml` + `config.toml`. Select with
`codex -p <name>`. CLI flags override the profile; the profile overrides the top-level default.

**Allowlist / execpolicy entry**
- Claude: add a `Bash(cmd:*)` prefix to `permissions.allow` in `settings.json`.
- Codex: a `prefix_rule(...)` lands in `rules/default.rules` automatically via `auto_review`
  (gitignored — machine-local on purpose; don't hand-curate the work machine's entries onto this one).

## Integrations registry

Install/update is **generic per tool** — don't write per-plugin prose (it rots against the tools'
own installers). Use the mechanics below + the table:

- **Claude:** `/plugin` to browse / install / enable (writes `enabledPlugins` in `settings.json`,
  fetches into the gitignored `plugins/` cache). Update via `/plugin`.
- **Codex:** `codex plugin marketplace add <owner/repo>` then install; or for a bare server
  `codex mcp add <name> --transport http <url>` (+ `codex mcp login <name>` if it does OAuth).
  Mirror shareable bits into `config.shared.toml`. Remote servers update server-side.
- **Deps** (browsers, CLIs) come from `brew bundle`.

| Integration | Tools | Scope | Auth | Enable |
|---|---|---|---|---|
| context-mode | both | shared | none | already enabled (plugin) |
| github | both | shared | OAuth | Claude plugin · Codex `codex mcp login github` |
| Google Drive | Claude | shared | OAuth | connector (already on) |
| context7 (live docs) | both | shared | none (free tier) | `/plugin` · `codex mcp add` |
| atlassian (Jira+Confluence) | both | **local / work** | OAuth | `/plugin` + login · `codex mcp add` + `codex mcp login` |
| playwright (browser) | both | shared | none (local browser) | `/plugin` · `codex mcp add` |

## Claude ↔ Codex parity (the keep-in-sync check)

Glance here when one tool gets a capability the other lacks.

| Concept | Claude Code | Codex CLI |
|---|---|---|
| Agent-behavior instructions | `claude/CLAUDE.md` | `codex/AGENTS.md` |
| Command allowlist | `permissions.allow` (string globs) | `rules/default.rules` (tokenized `prefix_rule`) |
| Compound-command approval | `hooks/approve-compound-bash.sh` (decomposes pipes/chains) | native — tokenized prefix matching, no decomposition needed |
| LLM approval reviewer | DIY `PreToolUse` prompt hook | native `approvals_reviewer = "auto_review"` |
| Hooks | `settings.json` hooks → `dispatch.sh` | `hooks.json` |
| Coarse trust dial | sandbox + bypass mode | `approval_policy` + `sandbox_mode` |
| Named modes | (none) | profiles (`-p strict/plan/auto`) |
| Shared/local split | `settings.json` (tracked) + `*.local.json` | `config.shared.toml` (tracked) + `config.toml` (gitignored) |
| GitHub MCP | official plugin (OAuth, managed) | `[mcp_servers.github]` + `codex mcp login` (OAuth) |

## Gotchas worth remembering

- **macOS bash is 3.2.** Anything needing bash 4.3+ (e.g. `approve-compound-bash.sh`) relies on the
  Homebrew bash re-exec — so Homebrew `bash` must be installed, or the hook silently no-ops (fail-closed).
- **`dispatch.sh doctor` blocks without stdin** — always `</dev/null`.
- **Codex `config.shared.toml` is a reference, not loaded** — changes there don't take effect until
  copied into `config.toml`. (Claude's `settings.json` *is* live, so it propagates on pull.)
- **`rules/default.rules` is gitignored** so machine/repo-specific learned rules don't bleed across
  machines; share a curated baseline as a `rules/*.dotfiles-reference-*` snapshot instead.
- **Codex GitHub MCP uses OAuth** (`codex mcp login github`) — no PAT in config or env; creds are
  stored encrypted and machine-local, so they aren't shared (run the login once per machine).
