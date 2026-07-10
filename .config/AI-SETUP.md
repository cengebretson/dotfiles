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
| `.local/bin/doctor` | health/audit entrypoint (`doctor ai` = hooks, integrations, deps, skills) | ✅ |
| `.local/bin/ai-hook-dispatch` | shared hook dispatcher; each tool's `hooks/dispatch.sh` symlinks to it | ✅ |
| `claude/hooks/handlers/`, `codex/hooks/handlers/` | per-tool hook handlers (shims tracked; machine-local symlinks like `domain-docs` 🚫 untracked) | ✅/🚫 |

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
   - Codex GitHub MCP (PAT path): set `GITHUB_PERSONAL_ACCESS_TOKEN` in `secrets.fish` **and** ensure
     `[mcp_servers.github]` in `config.toml` has `bearer_token_env_var = "GITHUB_PERSONAL_ACCESS_TOKEN"`
     (it's in `config.shared.toml`). `codex mcp login github` does **not** work — see Gotchas.
   - moshi (remote approvals/notifications, optional): `moshi-hook pair --token <token>` (token from
     the Moshi app; secret stored in the macOS keychain, per machine), then `brew services start
     moshi-hook` to run the `serve` daemon at every login (user LaunchAgent — maintains the socket +
     WebSocket bridge). Verify with `doctor ai` or `moshi-hook status` → `paired`. Do **not** run
     `moshi-hook install` — see Gotchas. Until paired, the `dispatch.sh moshi` routes no-op harmlessly.
5. **Codex live config:** copy the wanted blocks from `codex/config.shared.toml` into `codex/config.toml`
   (it's a reference, not auto-loaded). At minimum: `[mcp_servers.github]` and the `[profiles.*]`.
6. **Plugins:** enable the same set per the [Integrations registry](#integrations-registry) (Claude:
   `enabledPlugins` in `settings.json` is already tracked, so they re-fetch on first run; Codex:
   `codex plugin add …` / `codex mcp add …` as listed). 🧑 OAuth logins there are per-machine.
7. **Machine-local symlinks (only if `~/workspace/scripts` is cloned here)** 🤖:
   - the domain-docs session hook, an untracked symlink per tool:
   ```bash
   ln -s ../../../../workspace/scripts/analysis/automation/claude-session-hook.sh \
     ~/.config/claude/hooks/handlers/domain-docs
   ln -s ../../../../workspace/scripts/analysis/automation/claude-session-hook.sh \
     ~/.config/codex/hooks/handlers/domain-docs
   ```
   - the `los-scripts` command on `$PATH` (absolute-target symlink):
   ```bash
   ln -s /Users/cengebretson/workspace/scripts/bin/los-scripts ~/.local/bin/los-scripts
   ```
   Skip on machines without that repo — the `settings.json`/`hooks.json` entries degrade to logged
   skips, and `doctor ai` shows which handlers are inert.
8. **Verify:** `doctor ai` (one report: hooks, integrations, deps, skills parity) · `/health-check`
   (Claude) · `codex doctor`.

## How to add things (with the share-vs-local rule)

**MCP server**
- No secret + generic URL (token via `*_env_var` reference) → **shareable**.
  - Codex: `[mcp_servers.<name>]` in `config.shared.toml` *and* `config.toml`.
  - Claude: enable an official plugin in `settings.json` (preferred when one exists — it bundles
    managed OAuth + upkeep). For a bare server, `claude mcp add -s user <name> …` writes a user-scoped
    `mcpServers.<name>` entry into gitignored `~/.config/claude/.claude.json` (the mechanism actually
    in use for github); project-shared http servers can go in `.mcp.json`.
- Inline/hardcoded token, local stdio path, or work-only → **`config.toml` only** (gitignored).

**Hook**
- Both tools share one dispatcher: `.local/bin/ai-hook-dispatch`, symlinked as each tool's
  `hooks/dispatch.sh`. It runs the executable at `hooks/handlers/<name>` *next to the symlink it was
  invoked through*, so each tool gets its own handler set with zero per-tool dispatcher config.
- **To add a hook:** drop an executable (or symlink) at `claude/hooks/handlers/<name>` or
  `codex/hooks/handlers/<name>`, then reference `"dispatch.sh <name>"` from `settings.json` /
  `hooks.json`. Handler contract: payload arrives on stdin; **stdout passes through** (so
  context-injection *and* `PreToolUse` decision hooks both work through the dispatcher);
  side-effect handlers must self-suppress (`>/dev/null`); exit `0` = ok, exit `100` = prerequisite
  missing on this machine (logged `skipped`), anything else = failed. Logs: `hooks/logs/hooks.log`.
- Machine-specific handlers are **untracked symlinks** (e.g. `domain-docs` →
  `~/workspace/scripts/analysis/automation/claude-session-hook.sh`): they dangle harmlessly on
  machines without the target repo, and `doctor ai` reports them as such. Shared shims are tracked
  and self-check their own deps — see each tool's `hooks/handlers/` for the tracked shims.
- No per-hook doctor edits needed — `doctor ai` enumerates both handler dirs automatically.

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
| github | shared | user-scoped `mcpServers.github` in gitignored `~/.config/claude/.claude.json`, added via `claude mcp add -s user` 🤖 then OAuth 🧑 (the `github@claude-plugins-official` plugin is an alternative) | `[mcp_servers.github]` + `bearer_token_env_var = GITHUB_PERSONAL_ACCESS_TOKEN`, PAT in `secrets.fish` 🤖 — `codex mcp login github` **fails** (no OAuth DCR, see Gotchas) | `jq '.mcpServers \| keys' ~/.config/claude/.claude.json` · `codex mcp get github` · `mcp__github__*` resolves |
| playwright (browser) | shared | `playwright@claude-plugins-official` 🤖 | `codex mcp add playwright -- npx @playwright/mcp@latest` 🤖 (needs node) | tool list shows playwright |
| atlassian (Jira+Confluence) | **local/work** | `atlassian@claude-plugins-official` 🤖, then login 🧑 | `codex plugin add atlassian-rovo@openai-curated` 🤖, then `codex mcp login atlassian-rovo` 🧑 | server reachable after login |
| Google Drive | shared | Claude.ai **connector**, not a plugin — enable in app 🧑 | — | connector shows connected |

> **Optional (not currently installed):** context7 (live docs) — Claude: `context7@claude-plugins-official` 🤖;
> Codex: `codex mcp add context7 --url https://mcp.context7.com/mcp` 🤖; verify: tool list shows context7.
> Not in `enabledPlugins` and no Codex MCP entry on this machine — install only if wanted.

> `Codex.app` injects its own cowork plugins into shared `~/.codex` (`node_repl`, `documents`, `pdf`,
> `spreadsheets`, `presentations`, `template-creator`, `browser`) — they appear in `doctor ai` /
> `codex plugin list` but are **app-provided**, not part of this registry; nothing to install.

**Claude `enabledPlugins` edit shape** (the 🤖 agent path; example adding context7 + playwright):

```jsonc
// settings.json → "enabledPlugins" (official marketplace already known — no extraKnownMarketplaces needed)
"context7@claude-plugins-official": true,
"playwright@claude-plugins-official": true
```

Then restart Claude so the plugins fetch. For a plugin from a non-official marketplace, also add the
marketplace under `extraKnownMarketplaces` (see the existing `context-mode` entry as the template).

## Audit (setup status)

Run **`doctor ai`** (`~/.local/bin/doctor`, tracked) — one read-only report 🤖 covering deps, hook
plumbing for both tools (it enumerates each `hooks/handlers/` dir, flagging dangling symlinks as
"repo not on this machine"), integration/plugin state, and skills parity. It owns all health checks;
the dispatcher only dispatches. To get *"what's missing + how to install it,"* diff its
Integrations sections against the [registry](#integrations-registry): mark each row ✅/❌ per tool and
emit the ❌ row's install command (🤖) or human handoff (🧑). Skip `local/work` rows (atlassian)
unless asked.

Under the hood `doctor ai` enumerates state with these — use them directly for a single facet:

```bash
jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' ~/.config/claude/settings.json
codex mcp list
codex plugin list
```

**Deps:** `doctor ai` checks presence; `brew bundle --file ~/.config/Brewfile` installs/repairs any
missing formulae.

## Claude ↔ Codex parity (the keep-in-sync check)

Glance here when one tool gets a capability the other lacks.

| Concept | Claude Code | Codex CLI |
|---|---|---|
| Agent-behavior instructions | `claude/CLAUDE.md` | `codex/AGENTS.md` |
| Reusable skills | `claude/skills/<name>/SKILL.md` | `codex/skills/<name>/SKILL.md` (keep the set in sync; intentional Codex-only exemptions: `fast-loop` — Claude's loop behavior lives in CLAUDE.md — and `playwright` — Claude gets it via the official plugin; `doctor ai` skips both) |
| Command allowlist | `permissions.allow` (string globs) | `rules/default.rules` (tokenized `prefix_rule`) |
| Compound-command approval | `hooks/approve-compound-bash.sh` (decomposes pipes/chains) | native — tokenized prefix matching, no decomposition needed |
| LLM approval reviewer | DIY `PreToolUse` prompt hook | native `approvals_reviewer = "auto_review"` |
| Hooks | `settings.json` → `dispatch.sh` (symlink) → `hooks/handlers/*` | `hooks.json` → `dispatch.sh` (symlink) → `hooks/handlers/*` — one shared `ai-hook-dispatch` behind both |
| Coarse trust dial | sandbox + bypass mode | `approval_policy` + `sandbox_mode` |
| Named modes | (none) | profiles (`-p strict/plan/auto`) |
| Shared/local split | `settings.json` (tracked) + `*.local.json` | `config.shared.toml` (tracked) + `config.toml` (gitignored) |
| GitHub MCP | user-scoped `mcpServers.github` in gitignored `.claude.json` (`claude mcp add -s user`); official plugin is the managed-OAuth alternative | `[mcp_servers.github]` + PAT via `bearer_token_env_var` (no OAuth DCR) |
| Desktop app vs config | `Claude.app` keeps a **separate** store (`~/Library/Application Support/Claude/`, own MCP/connectors) — CLI config does **not** carry in | `Codex.app` **shares** `~/.codex/` (config, profiles, MCP, hooks, rules, auth) — only Electron state is app-local |
| Remote approvals/notify (moshi) | `dispatch.sh moshi` → `moshi-hook claude-hook` (9 hook events) | `dispatch.sh moshi` → `moshi-hook codex-hook` (4 hook events) |

## Gotchas worth remembering

- **macOS bash is 3.2.** Anything needing bash 4.3+ (e.g. `approve-compound-bash.sh`) relies on the
  Homebrew bash re-exec — so Homebrew `bash` must be installed, or the hook silently no-ops (fail-closed).
- **Codex `config.shared.toml` is a reference, not loaded** — changes there don't take effect until
  copied into `config.toml`. (Claude's `settings.json` *is* live, so it propagates on pull.)
- **`rules/default.rules` is gitignored** so machine/repo-specific learned rules don't bleed across
  machines; share a curated baseline as a `rules/*.dotfiles-reference-*` snapshot instead.
- **Codex GitHub MCP uses a PAT, not OAuth.** `codex mcp login github` fails with *"Dynamic client
  registration not supported"* — the Copilot MCP endpoint (`api.githubcopilot.com/mcp`) doesn't offer
  OAuth DCR. Authenticate with a PAT: `bearer_token_env_var = "GITHUB_PERSONAL_ACCESS_TOKEN"` in the
  `[mcp_servers.github]` block of the live `config.toml`, token set in `secrets.fish` (machine-local).
  Restart Codex after adding it; verify with `codex mcp get github`.
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
- **moshi is wired through `dispatch.sh moshi`, NOT `moshi-hook install` — ignore the "stale" nag.**
  The hook events route to `moshi-hook claude-hook`/`codex-hook` via the dispatcher (keeps
  `settings.json`/`hooks.json` portable). So `moshi-hook status` always reports hooks `stale / missing`
  and says "rerun `moshi-hook install`" — **don't.** `moshi-hook install` writes its own
  machine-specific hook entries that duplicate/conflict with the dispatcher routing. `moshi-hook`
  comes from `brew bundle` (`rjyo/moshi/moshi-hook`); the pairing secret lives in the macOS keychain
  (machine-local, never committed); `doctor ai` checks the binary is present, not that it's paired.
