# AI Tooling Setup

Human runbook for the AI coding agents on this machine (**Claude Code** + **Codex CLI**):
how to bootstrap a fresh clone, how to add things, and how to keep the two in sync.

> This is **not** agent-behavior config. That lives in `claude/CLAUDE.md` and `codex/AGENTS.md`
> (which the agents auto-read every session — keep setup steps *out* of them). This file is for a
> human (or an agent explicitly asked to set up a machine). Component reference for Claude's
> statusline/tools is in `claude/README.md`.

## Who this is for (human vs agent)

Two readers use this file: a **human** doing a one-time bootstrap, and an **agent** explicitly asked
to "set up this machine" / "install the plugins I need." Steps are tagged by who can do them:

- 🤖 **agent-safe** — non-interactive: edit a tracked config, run a CLI install, `brew bundle`.
- 🧑 **human-only** — interactive auth or a secret an agent must not author: OAuth browser flows,
  PAT/secret entry, app sign-in.

**Agent runbook:** work an integration's row top-to-bottom; do the 🤖 parts; at each 🧑 step, print
the *literal* login/secret command and pause for the human (suggest the `! <cmd>` prefix so its output
lands in the session). After any Claude `enabledPlugins`/marketplace edit, tell the human to **restart
Claude** — plugins fetch at session start, so the running session won't see them. Confirm each row
with its Verify command before moving on. Never create or commit a file from the 🚫-gitignored set.

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
| `.local/bin/ai-doctor` | one-command health/audit report (hooks, integrations, deps, skills) | ✅ |

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
6. **Plugins:** enable the same set per the [Integrations registry](#integrations-registry) (Claude:
   `enabledPlugins` in `settings.json` is already tracked, so they re-fetch on first run; Codex:
   `codex plugin add …` / `codex mcp add …` as listed). 🧑 OAuth logins there are per-machine.
7. **Verify:** `ai-doctor` (one report: hooks, integrations, deps, skills parity) · `/health-check`
   (Claude) · `codex doctor`.

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

**Allowlist / execpolicy entry** — *keep Claude's list minimal.*
- Claude: **only add commands that escape the sandbox** — network (`gh`, `git push/fetch`, package
  managers) or writes *outside* the repo. Do **not** add read-only commands (`rg`/`cat`/`ls`/`grep`)
  or in-repo writes (`git commit`/`git add`) — the sandbox auto-allows those, so listing them is dead
  weight. This relies on the `sandbox` block in `settings.json` (tracked, so it propagates on clone):
  ```json
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "filesystem": { "allowWrite": ["/tmp", "/private/tmp"] }
  }
  ```
- Codex: a `prefix_rule(...)` lands in `rules/default.rules` automatically via `auto_review`
  (gitignored — machine-local on purpose; don't hand-curate the work machine's entries onto this one).

## Integrations registry

Install/update is **generic per tool** — these mechanics + the table cover every row; don't write
per-plugin prose (it rots against the tools' own installers).

**Mechanics**
- **Claude — agent path (no TUI):** edit `settings.json` directly — add `"<plugin>@<marketplace>": true`
  to `enabledPlugins`; if the marketplace isn't `claude-plugins-official`, also add it to
  `extraKnownMarketplaces`. Plugins fetch on the **next session start** (restart required). The
  `claude-plugins-official` and `context-mode` (`mksglu/context-mode`) marketplaces are already known.
- **Claude — human path:** `/plugin` to browse/install/enable (writes the same `enabledPlugins`).
- **Codex — marketplace plugin:** `codex plugin add <plugin>@<marketplace>` (run `codex plugin list`
  to see names; `openai-curated` ships with the CLI). Add a 3rd-party marketplace first with
  `codex plugin marketplace add <owner/repo|url>`.
- **Codex — bare MCP server:** HTTP → `codex mcp add <name> --url <url> [--bearer-token-env-var <VAR>]`;
  stdio → `codex mcp add <name> [--env K=V] -- <cmd>…`. Mirror shareable bits into `config.shared.toml`.
  OAuth servers also need `codex mcp login <name>` (🧑).
- **Deps** (browsers, CLIs) come from `brew bundle`.

| Integration | Scope | Claude (`enabledPlugins` id / how) | Codex (command) | Verify |
|---|---|---|---|---|
| context-mode | shared | `context-mode@context-mode` 🤖 | `codex plugin add context-mode@context-mode` 🤖 | `/health-check` · `codex plugin list` |
| github | shared | `github@claude-plugins-official` 🤖, then OAuth 🧑 | `[mcp_servers.github]` + PAT in `secrets.fish` 🤖, **or** `codex mcp login github` 🧑 | `codex mcp list` · `mcp__github__*` resolves |
| context7 (live docs) | shared | `context7@claude-plugins-official` 🤖 | `codex mcp add context7 --url https://mcp.context7.com/mcp` 🤖 | tool list shows context7 |
| playwright (browser) | shared | `playwright@claude-plugins-official` 🤖 | `codex mcp add playwright -- npx @playwright/mcp@latest` 🤖 (needs node) | tool list shows playwright |
| atlassian (Jira+Confluence) | **local/work** | `atlassian@claude-plugins-official` 🤖, then login 🧑 | `codex plugin add atlassian-rovo@openai-curated` 🤖, then `codex mcp login atlassian-rovo` 🧑 | server reachable after login |
| Google Drive | shared | Claude.ai **connector**, not a plugin — enable in app 🧑 | — | connector shows connected |

**Claude `enabledPlugins` edit shape** (the 🤖 agent path; example adding context7 + playwright):

```jsonc
// settings.json → "enabledPlugins" (official marketplace already known — no extraKnownMarketplaces needed)
"context7@claude-plugins-official": true,
"playwright@claude-plugins-official": true
```

Then restart Claude so the plugins fetch. For a plugin from a non-official marketplace, also add the
marketplace under `extraKnownMarketplaces` (see the existing `context-mode` entry as the template).

## Audit (setup status)

Run **`ai-doctor`** (`~/.local/bin/ai-doctor`, tracked) — one read-only report 🤖 covering deps, hook
plumbing for both tools, integration/plugin state, and skills parity. It owns all health checks; the
`dispatch.sh` scripts only dispatch now. To get *"what's missing + how to install it,"* diff its
Integrations sections against the [registry](#integrations-registry): mark each row ✅/❌ per tool and
emit the ❌ row's install command (🤖) or human handoff (🧑). Skip `local/work` rows (atlassian)
unless asked.

Under the hood `ai-doctor` enumerates state with these — use them directly for a single facet:

```bash
jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' ~/.config/claude/settings.json
codex mcp list
codex plugin list
```

**Deps:** `ai-doctor` checks presence; `brew bundle --file ~/.config/Brewfile` installs/repairs any
missing formulae.

## Claude ↔ Codex parity (the keep-in-sync check)

Glance here when one tool gets a capability the other lacks.

| Concept | Claude Code | Codex CLI |
|---|---|---|
| Agent-behavior instructions | `claude/CLAUDE.md` | `codex/AGENTS.md` |
| Reusable skills | `claude/skills/<name>/SKILL.md` | `codex/skills/<name>/SKILL.md` (keep the set in sync) |
| Command allowlist | `permissions.allow` (string globs) | `rules/default.rules` (tokenized `prefix_rule`) |
| Compound-command approval | `hooks/approve-compound-bash.sh` (decomposes pipes/chains) | native — tokenized prefix matching, no decomposition needed |
| LLM approval reviewer | DIY `PreToolUse` prompt hook | native `approvals_reviewer = "auto_review"` |
| Hooks | `settings.json` hooks → `dispatch.sh` | `hooks.json` |
| Coarse trust dial | sandbox + bypass mode | `approval_policy` + `sandbox_mode` |
| Named modes | (none) | profiles (`-p strict/plan/auto`) |
| Shared/local split | `settings.json` (tracked) + `*.local.json` | `config.shared.toml` (tracked) + `config.toml` (gitignored) |
| GitHub MCP | official plugin (OAuth, managed) | `[mcp_servers.github]` + `codex mcp login` (OAuth) |
| Desktop app vs config | `Claude.app` keeps a **separate** store (`~/Library/Application Support/Claude/`, own MCP/connectors) — CLI config does **not** carry in | `Codex.app` **shares** `~/.codex/` (config, profiles, MCP, hooks, rules, auth) — only Electron state is app-local |

## Gotchas worth remembering

- **macOS bash is 3.2.** Anything needing bash 4.3+ (e.g. `approve-compound-bash.sh`) relies on the
  Homebrew bash re-exec — so Homebrew `bash` must be installed, or the hook silently no-ops (fail-closed).
- **Codex `config.shared.toml` is a reference, not loaded** — changes there don't take effect until
  copied into `config.toml`. (Claude's `settings.json` *is* live, so it propagates on pull.)
- **`rules/default.rules` is gitignored** so machine/repo-specific learned rules don't bleed across
  machines; share a curated baseline as a `rules/*.dotfiles-reference-*` snapshot instead.
- **Codex GitHub MCP uses OAuth** (`codex mcp login github`) — no PAT in config or env; creds are
  stored encrypted and machine-local, so they aren't shared (run the login once per machine).
- **The minimal Claude allowlist is load-bearing on the sandbox.** `sandbox.enabled` +
  `autoAllowBashIfSandboxed` (tracked in `settings.json`) are what auto-approve read-only + in-repo-write
  commands — which is why ~half the allowlist could be deleted. Disable the sandbox and those start
  prompting again. Don't remove that block, and don't re-add `rg`/`cat`/`git commit`/etc. "to be safe."
- **The desktop apps are not symmetric.** `Codex.app` (Electron) **shares** `~/.codex/` with the CLI —
  it reads `config.toml`, profiles, MCP, `hooks.json`, `rules/`, `auth.json`; only Chromium/Electron
  state lives in `~/Library/Application Support/Codex`. `Claude.app` is the opposite: it keeps its own
  config (`~/Library/Application Support/Claude/claude_desktop_config.json`, connectors), and Claude
  Code's `settings.json`/hooks/plugins do **not** carry into it. Only Claude *Code* surfaces (terminal,
  IDE extension) share `~/.config/claude`. To run app-free, the sole thing you lose is Claude's Google
  Drive connector (app-only); everything else works headless from the CLI.
- **`Codex.app` bundles its own `codex` engine — it can drift from the brew CLI.** Config is shared,
  but the app's binary (`/Applications/Codex.app/Contents/Resources/codex`) and the plugin versions it
  resolves may differ from `/opt/homebrew/bin/codex` (seen: app on context-mode 1.0.162 vs CLI 1.0.166).
  If the app and terminal behave differently, compare versions first.
