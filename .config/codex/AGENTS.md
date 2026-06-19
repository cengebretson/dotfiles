# Global Codex Instructions

## Working Style

- At the start of a new session, use `$health-check` before substantive work and report the result. If the skill is unavailable, perform the same manual checks covering repository tools, issue-tracker/MCP tools, context-mode/plugin availability, and SSH agent status.
- Bias toward action. When the next step is obvious and already within the user's request, do it and report what happened.
- Pause for genuinely consequential or ambiguous decisions: destructive actions, broad permission changes, public publishing, or choices where the user's answer changes the outcome.
- Keep responses direct, pragmatic, and concise. Prefer concrete file paths, commands, and verification results over general explanation.
- Do not add AI attribution, "Generated with..." footers, or `Co-Authored-By` lines to commits or PR text.

## Tool Selection

- Prefer MCP/app/plugin tools over raw CLI or REST when an available tool covers the operation.
- For GitHub work, check for a GitHub MCP/app tool before using `gh` or `curl`. If no suitable tool is available or the tool fails, say that you are falling back to CLI before using it.
- Use `rg` for text search and `rg --files` for file search before slower alternatives.
- Prefer structured tools/parsers for structured data. Use `jq` for JSON and `yq` for YAML/TOML/JSON when appropriate.
- Prefer installed higher-signal CLI tools when they fit:
  - `ast-grep` for syntax-aware code search or rewrites.
  - `difftastic` for structural diffs.
  - `shellcheck` for shell scripts.
  - `sd` for simple find-and-replace.
  - `scc` for codebase line/complexity overviews.
  - `fd` for ergonomic file search.
  - `bat`, `eza`, and `glow` for human-facing display when useful.

## Environment

- Interactive shell preference: Fish.
- Scripts, hooks, and non-interactive commands should use Bash with `#!/usr/bin/env bash` unless the project says otherwise.
- Editor: nvim.
- Terminal: Ghostty + tmux.
- Color scheme preference: Catppuccin Mocha.

## Dotfiles

- Dotfiles are tracked in a bare git repository. Use this form for dotfiles git operations:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" <command>
```

- `dots` is a Fish abbreviation, not a real command. Do not use it in scripts, tool calls, or non-interactive commands.
- Machine-local files must not be committed or hardcoded:
  - `~/.config/git/config.local`
  - `~/.config/fish/secrets.fish`
  - `~/.config/claude/.claude.json`
- For Codex settings, keep `~/.config/codex/config.toml` untracked because it contains machine-local trust state, absolute paths, and hook hashes. Use `~/.config/codex/config.shared.toml` as the tracked reference for portable settings, and ask before copying any shared setting into the live `config.toml`.
- If changing Fish config, validate changed Fish files with `fish -n` before finishing.
- Fisher-generated files under `functions/`, `conf.d/`, or `completions/` should not be committed unless they are intentional custom dotfiles.

## Git And Commits

- Never run destructive git commands such as `git reset --hard` or `git checkout --` without explicit user authorization.
- Do not revert user changes unless the user explicitly asks.
- Keep commits focused and authored solely by the user.
- Never add AI attribution to commits, PR descriptions, or generated notes.

## Validation

- Run targeted checks that match the changed files and project conventions.
- If sandboxed commands warn that they cannot write under `~/Library/Caches` for `mise` or Go build cache, rerun with temp cache dirs such as `MISE_CACHE_DIR=/private/tmp/mise-cache GOCACHE=/private/tmp/go-build-cache` and do not treat the warning as a project failure.
- Validate Lua changes with `luac -p <file>` when working on Neovim/Lua config.
- Validate shell scripts with `shellcheck` when available.
- For Fish files, run `fish -n <file>`.

## Tool Gotchas

- `rg`: `-h` means `--help`, not "no filename". Use `--no-filename` or `-I` for no-filename output.
- If a command unexpectedly prints a tool's help text, assume a bad flag and fix the command before trusting the output.

---

# context-mode — MANDATORY routing rules

context-mode MCP tools available. Rules protect context window from flooding. One unrouted command dumps 56 KB into context. Codex CLI hooks provide runtime enforcement when `[features].hooks = true`; these instructions remain mandatory model-side enforcement. Follow strictly.

## Think in Code — MANDATORY

Analyze/count/filter/compare/search/parse/transform data: **write code** via `ctx_execute(language, code)`, `console.log()` only the answer. Do NOT read raw data into context. PROGRAM the analysis, not COMPUTE it. Pure JavaScript — Node.js built-ins only (`fs`, `path`, `child_process`). `try/catch`, handle `null`/`undefined`. One script replaces ten tool calls.

## BLOCKED — do NOT use

### curl / wget — FORBIDDEN
Do NOT use `curl`/`wget` in shell. Dumps raw HTTP into context.
Use: `ctx_fetch_and_index(url, source)` or `ctx_execute(language: "javascript", code: "const r = await fetch(...)")`

### Inline HTTP — FORBIDDEN
No `node -e "fetch(..."`, `python -c "requests.get(..."`. Bypasses sandbox.
Use: `ctx_execute(language, code)` — only stdout enters context

### Direct web fetching — FORBIDDEN
Raw HTML can exceed 100 KB.
Use: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)`

## REDIRECTED — use sandbox

### Shell (>20 lines output)
Shell ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`.
Otherwise: `ctx_batch_execute(commands, queries)` or `ctx_execute(language: "shell", code: "...")`

### File reading (for analysis)
Reading to **edit** → reading correct. Reading to **analyze/explore/summarize** → `ctx_execute_file(path, language, code)`.

### grep / search (large results)
Use `ctx_execute(language: "shell", code: "grep ...")` in sandbox.

## Tool selection

0. **MEMORY**: `ctx_search(sort: "timeline")` — after resume, check prior context before asking user.
1. **GATHER**: `ctx_batch_execute(commands, queries)` — runs all commands, auto-indexes, returns search. ONE call replaces 30+. Each command: `{label: "header", command: "..."}`.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — all questions as array, ONE call (default relevance mode).
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — sandbox, only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — store in FTS5 for later search.

## Quiet output

When using context-mode for tests, builds, lint, searches, or other commands that
can produce large output, filter aggressively and print only failures, actionable
diagnostics, or a short pass/fail summary. Do not return full passing logs unless
the user explicitly asks for them.

## Parallel I/O batches

For multi-URL fetches or multi-API calls, **always** include `concurrency: N` (1-8):

- `ctx_batch_execute(commands: [3+ network commands], concurrency: 5)` — gh, curl, dig, docker inspect, multi-region cloud queries
- `ctx_fetch_and_index(requests: [{url, source}, ...], concurrency: 5)` — multi-URL batch fetch

**Use concurrency 4-8** for I/O-bound work (network calls, API queries). **Keep concurrency 1** for CPU-bound (npm test, build, lint) or commands sharing state (ports, lock files, same-repo writes).

GitHub API rate-limit: cap at 4 for `gh` calls.

## Output

Write artifacts to FILES — never inline. Return: file path + 1-line description.
Descriptive source labels for `ctx_search(source: "label")`.

## Session Continuity

Skills, roles, and decisions persist for the entire session. Do not abandon them as the conversation grows.

## Memory

Session history is persistent and searchable. On resume, search BEFORE asking the user:

| Need | Command |
|------|---------|
| What were we working on? | `ctx_search(queries: ["summary"], source: "compaction", sort: "timeline")` |
| What did we decide? | `ctx_search(queries: ["decision"], source: "decision", sort: "timeline")` |
| What NOT to repeat? | `ctx_search(queries: ["rejected"], source: "rejected-approach")` |
| What constraints exist? | `ctx_search(queries: ["constraint"], source: "constraint")` |

Note: user-prompt history not available.

DO NOT ask "what were we working on?" — SEARCH FIRST.
If search returns 0 results, proceed as a fresh session.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call `stats` MCP tool, display full output verbatim |
| `ctx doctor` | Call `doctor` MCP tool, run returned shell command, display as checklist |
| `ctx upgrade` | Call `upgrade` MCP tool, run returned shell command, display as checklist |
| `ctx purge` | Call `purge` MCP tool with confirm: true. Warns before wiping knowledge base. |

After /clear or /compact: knowledge base and session stats preserved. Use `ctx purge` to start fresh.

## Windows notes

**PowerShell cmdlets** — Sandbox uses bash. PowerShell cmdlets (`Format-List`, `Get-Culture`, etc.) fail with `command not found`. Wrap with `pwsh -NoProfile -Command "..."`.

**Relative paths** — Sandbox CWD is temp dir, not project root. Convert to absolute paths. Ask user to confirm if unknown.

**Windows drive letters** — Sandbox runs Git Bash / MSYS2. `X:\path` → `/x/path` (lowercase, no `/mnt/`). Never emit `/mnt/<letter>/`.

**Quote paths** — Spaces in paths cause splits. Always double-quote: `rg "symbol" "$REPO_ROOT/some dir/Source"`.
