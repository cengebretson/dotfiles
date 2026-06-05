# coral — Plugin Spec

Git branch browser for fish shell. Built on fzf with GitHub PR status, inline preview, and tmux popup actions.

---

## Repo Structure

Fisher expects a flat `functions/` directory. The plugin ships all files under `functions/` in a public GitHub repo.

```
coral/
├── functions/
│   ├── coral.fish
│   ├── _coral_base_branch.fish
│   ├── _coral_cache_dir.fish
│   ├── _coral_cache_file.fish
│   ├── _coral_cache_ttl.fish
│   ├── _coral_clear_cache.fish
│   ├── _coral_config_file.fish
│   ├── _coral_confirm.fish
│   ├── _coral_delete_branch.fish
│   ├── _coral_delete_common.fish
│   ├── _coral_doctor.fish
│   ├── _coral_doctor_command.fish
│   ├── _coral_doctor_fail.fish
│   ├── _coral_doctor_ok.fish
│   ├── _coral_doctor_section.fish
│   ├── _coral_doctor_value.fish
│   ├── _coral_doctor_warn.fish
│   ├── _coral_file_mtime.fish
│   ├── _coral_force_delete_branch.fish
│   ├── _coral_jira_pattern.fish
│   ├── _coral_jira_url.fish
│   ├── _coral_label_badge.fish
│   ├── _coral_list.fish
│   ├── _coral_load_config.fish
│   ├── _coral_open_jira.fish
│   ├── _coral_open_pr.fish
│   ├── _coral_popup.fish
│   ├── _coral_pr_batch_size.fish
│   ├── _coral_pr_entries.fish
│   ├── _coral_pr_history_days.fish
│   ├── _coral_preview.fish
│   ├── _coral_rebase.fish
│   ├── _coral_run_delete.fish
│   ├── _coral_run_rebase.fish
│   ├── _coral_since_date.fish
│   ├── _coral_slack.fish
│   ├── _coral_upstream.fish
│   ├── _coral_version.fish
│   ├── _coral_worktree_list.fish
│   └── _coral_worktree_path.fish
├── README.md
└── conf.d/
    └── coral.fish          ← dependency check at shell start (see below)
```

---

## Dependencies

### Hard (coral will not start without these)

| Tool | Min version | Check | Install |
|------|-------------|-------|---------|
| fish | 3.3+ | `fish --version` | brew/pkg |
| git | any | `command -q git` | system |
| fzf | 0.57+ | `fzf --version` | brew install fzf |
| fzf.fish (PatrickF1) | any | `functions -q _fzf_wrapper` | fisher install PatrickF1/fzf.fish |
| jq | any | `command -q jq` | brew install jq |
| shasum | any | `command -q shasum` | ships with macOS/Linux |

**fzf ≥ 0.57** is required for `--input-border` and `--list-border` flags. Older versions will fail silently with layout errors.

Hard dependency checks should be available through `coral --doctor` and should also prevent the main `coral` command from opening a broken UI. Startup checks in `conf.d/coral.fish` should warn sparingly so every new shell does not become noisy.

### Preferred optional tools (coral degrades gracefully without these)

| Tool | Degradation |
|------|-------------|
| gh (GitHub CLI) | Branch browsing remains available; PR columns show unavailable/auth-needed state; PR open/rebase keybinds show one clean message |
| gum | Confirms fall back to fzf Yes/No picker |
| tmux | Delete/rebase/review popups fall back to blocking `execute` / `execute-silent` fzf binds plus reload |
| curl | fzf list auto-reload after popup actions unavailable; user must press ⌥r manually |

---

## Configuration

Settings live in native fish config:

```text
$XDG_CONFIG_HOME/coral/config.fish
```

with fallback:

```text
~/.config/coral/config.fish
```

The config file is optional. If it is missing, coral uses the defaults below. Use regular fish globals in the config file; they do not need to be exported.

| Setting | Default | Purpose |
|-----|---------|---------|
| `CORAL_BASE_BRANCHES` | `develop\|main\|master\|release/\|hotfix/` | ERE alternation for base branch detection in `_coral_upstream`. Override for trunk-based or custom workflows |
| `CORAL_CACHE_TTL` | `300` | Repo PR cache TTL in seconds. Positive integers only; invalid values fall back to `300` |
| `CORAL_COLOR_ACCENT` | `#CBA6F7` | gum selected button / regular-delete branch name color |
| `CORAL_COLOR_BG` | `#1E1E2E` | gum selected button foreground |
| `CORAL_COLOR_DANGER` | `#F38BA8` | gum force-delete branch name color |
| `CORAL_COLOR_MUTED` | `#6C7086` | gum unselected button color |
| `CORAL_COLOR_TEXT` | `#CDD6F4` | gum prompt text color |
| `CORAL_JIRA_KEY_PATTERN` | `[A-Z]+-[0-9]+` | Regex used to extract a Jira issue key from the selected branch |
| `CORAL_JIRA_URL_TEMPLATE` | _(unset)_ | URL template for Jira issues. Use `{key}` as the issue-key placeholder, e.g. `https://yourorg.atlassian.net/browse/{key}` |
| `CORAL_PR_BATCH_SIZE` | `10` | Max concurrent branch-scoped `gh pr list --head` lookups during cache refresh. Positive integers only; invalid values fall back to `10` |
| `CORAL_PR_HISTORY_DAYS` | `30` | How far back to include merged/closed PRs by `updatedAt`. Set `0` to show open PRs only; invalid values fall back to `30` |

Example config:

```fish
set -g CORAL_JIRA_URL_TEMPLATE 'https://yourorg.atlassian.net/browse/{key}'
set -g CORAL_PR_BATCH_SIZE 10
set -g CORAL_PR_HISTORY_DAYS 30
```

Cache files live in:

```text
$XDG_CACHE_HOME/coral/pr
```

with fallback:

```text
~/.cache/coral/pr
```

---

## conf.d startup check

Create `conf.d/coral.fish` to surface missing hard deps with a clear message instead of cryptic runtime errors. Keep this lightweight and quiet: detailed validation belongs in `coral --doctor`, and startup should not print repeated warnings in every shell once the user has seen them.

```fish
# conf.d/coral.fish
if not functions -q _fzf_wrapper
    echo "coral: fzf.fish not installed — run: fisher install PatrickF1/fzf.fish" >&2
end

if not command -q fzf
    echo "coral: fzf not found — run: brew install fzf" >&2
    return
end

# fzf >= 0.57 required for --input-border / --list-border flags
set -l fzf_ver (fzf --version 2>/dev/null | string match -r '\d+\.\d+' | head -1)
if test -n "$fzf_ver"
    set -l major (string split . $fzf_ver)[1]
    set -l minor (string split . $fzf_ver)[2]
    if test "$major" -eq 0 -a "$minor" -lt 57
        echo "coral: fzf $fzf_ver found but ≥ 0.57 required — run: brew upgrade fzf" >&2
    end
end

if not command -q jq
    echo "coral: jq not found — run: brew install jq" >&2
end
```

The main `coral` command should perform the same hard checks before opening fzf and return non-zero when a hard dependency is missing.

---

## Fallback behavior

Preferred tools should improve the experience but must not be required for branch browsing.

| Capability | Preferred path | Fallback path |
|------------|----------------|---------------|
| Branch selection / checkout | fzf.fish wrapper around fzf | No fallback; this is core |
| PR status columns | `gh` authenticated to the current repo host | Blank or muted unavailable column; branch list still works |
| Open PR in browser | `gh pr view --web` | Show a clean "gh unavailable" message |
| Open Jira issue | `CORAL_JIRA_URL_TEMPLATE` + Jira key parsed from branch | Show a clean "CORAL_JIRA_URL_TEMPLATE is not set" message |
| Rebase action UI | tmux popup | Blocking fzf execute bind, then reload list |
| Delete action UI | tmux popup + gum confirmation | Blocking fzf execute bind + fzf Yes/No picker |
| Confirmation prompts | gum confirm/choose with theme colors | fzf Yes/No picker |
| Post-action reload | curl-triggered fzf reload where needed | User can press refresh keybind manually |
| Cache refresh | repo-specific cache file via `_coral_clear_cache` | no-op when repo cache cannot be resolved |

When an optional tool is absent, keybinds should either remain useful through a fallback or fail with one concise message. Avoid stack traces, raw command errors, or partially drawn fzf panes.

---

## Keybindings

| Key | Action | Notes |
|-----|--------|-------|
| `Enter` | Checkout selected branch | If the branch is checked out in a linked worktree, open that worktree in a tmux window when tmux is available |
| `Ctrl-o` | Open GitHub PR | Uses `_coral_open_pr`; shows a clean message if `gh` is unavailable or no PR exists |
| `Ctrl-j` | Open Jira issue | Always visible. Requires `CORAL_JIRA_URL_TEMPLATE` and a Jira key parsed from the branch name |
| `Ctrl-p` | Toggle preview | Preview includes PR info, Jira URL, worktree path, commits ahead, and changed files |
| `Alt-e` | Rebase branch | Uses PR base when available, otherwise inferred upstream |
| `Alt-D` | Delete selected branch | Header says `delete`; force-delete wording is shown only inside the confirmation popup |
| `Alt-r` | Refresh | Clears only the current repo's PR cache and reloads the list |

Subcommands:

| Command | Action |
|---------|--------|
| `coral --doctor` | Print dependency, configuration, repo, cache, and GitHub auth diagnostics |
| `coral --slack [filter ...]` | Print open local-branch PRs as Slack-friendly links, optionally filtered by branch/title/label terms |
| `coral --version` | Print the coral version |

---

## Cache and PR lookup

Cache helpers are intentionally separate so list rendering, refresh keybinds, and tests share one implementation:

| Helper | Responsibility |
|--------|----------------|
| `_coral_base_branch` | resolve remote HEAD, then local `main`, `master`, `develop`, then current branch |
| `_coral_cache_dir` | resolve and create the XDG cache directory for PR cache files |
| `_coral_cache_file` | resolve the current repo's PR cache path from `origin` URL hash |
| `_coral_cache_ttl` | parse `CORAL_CACHE_TTL`, defaulting invalid values to `300` |
| `_coral_clear_cache` | remove only the current repo's cache file |
| `_coral_config_file` | resolve the XDG config file path |
| `_coral_confirm` | confirmation UI, using gum when present and fzf fallback otherwise |
| `_coral_delete_common` | shared regular/force branch deletion flow |
| `_coral_doctor*` | read-only diagnostics for dependencies, config, repo state, cache, and GitHub auth |
| `_coral_file_mtime` | return cache mtime using BSD `stat -f %m` or GNU `stat -c %Y` |
| `_coral_label_badge` | render GitHub label names as ANSI badges for preview |
| `_coral_jira_url` | resolve a parsed Jira key through `CORAL_JIRA_URL_TEMPLATE` |
| `_coral_load_config` | source optional config file and install defaults |
| `_coral_open_jira` | open parsed Jira key URL |
| `_coral_open_pr` | open selected branch's PR through `gh` |
| `_coral_popup` | tmux popup wrapper plus optional fzf reload |
| `_coral_pr_batch_size` | parse `CORAL_PR_BATCH_SIZE`, defaulting invalid values to `10` |
| `_coral_pr_entries` | batch-fetch PR metadata for stale local branch heads and emit branch/SHA cache rows |
| `_coral_pr_history_days` | parse `CORAL_PR_HISTORY_DAYS`, defaulting invalid values to `30` |
| `_coral_preview` | right-side preview content |
| `_coral_since_date` | compute a portable YYYY-MM-DD cutoff date for PR history search |
| `_coral_slack` | render open local-branch PRs from cache as Slack-friendly links |
| `_coral_upstream` | infer rebase/diff upstream for branches without PR base metadata |
| `_coral_version` | print the current coral version |
| `_coral_worktree_list` / `_coral_worktree_path` | detect linked worktrees and their paths |

`CORAL_CACHE_TTL` validation:

```fish
set -f cache_ttl 300
if set -q CORAL_CACHE_TTL; and string match -qr '^[0-9]+$' -- $CORAL_CACHE_TTL; and test $CORAL_CACHE_TTL -gt 0
    set cache_ttl $CORAL_CACHE_TTL
end
```

Invalid values should fall back to `300` without breaking the branch list.

Default PR lookup should be scoped to the local branches coral is displaying:

- collect local branch names from `_coral_list`
- include each local branch's current commit SHA in the cache row
- keep "no PR" cache rows so branches without PRs are not rechecked until their SHA changes or cache TTL expires
- call `gh pr list --head <branch> --state all --limit 20` for those branch heads
- run branch lookups in parallel batches capped by `CORAL_PR_BATCH_SIZE`
- keep open PRs regardless of age
- keep merged/closed PRs only when `updatedAt` is inside `CORAL_PR_HISTORY_DAYS`

This avoids missing older open PRs in large repositories where repo-wide `--state all --limit 200` can be dominated by recent closed/merged PR history. It also avoids fetching every open PR in the repo when the user only needs status for local branches. Once cached, unchanged branch heads are reused without a GitHub call; new or moved branch heads are refreshed selectively. `CORAL_PR_HISTORY_DAYS` controls the merged/closed lookback window and defaults to `30`; set it to `0` for open-PR-only status.

Cache row format uses ASCII unit separator (`\x01`):

```text
branch<US>local_sha<US>state<US>reviewDecision<US>labels<US>title<US>baseRefName<US>url
```

For branches with no matching PR, `state` and later PR fields are empty. This negative cache row is intentional.

Only valid `gh` JSON array responses may create negative cache rows. Empty files, invalid JSON, auth failures, network failures, or other `gh` errors must not be cached as "no PR".

Base branches such as `develop`, `main`, and `master` are hidden by default to keep the branch browser focused, but the currently checked-out branch must always be shown and highlighted even when it is a base branch.

---

## Testing

Use [fishtape](https://github.com/jorgebucaran/fishtape) as the default test runner. It is a pure-fish TAP test runner, which fits a Fisher plugin better than Bats or shellspec because the code under test is fish-native.

Suggested layout:

```text
~/.config/coral/
├── tests/
│   ├── helpers.fish
│   ├── cache.test.fish
│   ├── config.test.fish
│   ├── validation.test.fish
│   └── version.test.fish
```

Run with:

```fish
fishtape ~/.config/coral/tests/*.test.fish
```

Minimum test coverage before publishing:

- `coral --version` prints the current version
- XDG config/cache paths resolve correctly
- config file values load and missing settings fall back to defaults
- Jira URL template replaces `{key}`
- dependency doctor output for missing hard deps
- branch list works when `gh`, `gum`, and `tmux` are absent
- PR columns degrade cleanly when `gh` is absent or unauthenticated
- confirmation falls back from gum to fzf
- delete/rebase actions fall back when tmux is absent
- `CORAL_CACHE_TTL` accepts positive integers and rejects invalid values
- `CORAL_PR_BATCH_SIZE` defaults to 10 and rejects invalid values
- `CORAL_PR_HISTORY_DAYS` defaults to 30, accepts 0, and rejects invalid values
- open PRs are not dropped in repos with more than 200 recent all-state PRs
- PR lookup queries only local branch heads, not every open PR in the repo
- unchanged branch/SHA cache rows avoid repeat GitHub calls
- branches with no PR are cached as misses
- failed or invalid `gh` responses do not create negative cache rows
- current branch is shown and highlighted even when it is `develop`, `main`, or `master`
- `coral --slack [filter ...]` outputs only open local-branch PRs with Slack `<url|title>` links; filters match branch, title, and labels
- refresh removes only the current repo's cache
- no remote, no upstream, detached HEAD, and non-Git directory behavior
- branch checked out in another worktree is detected and protected

---

## README sections needed

1. **What it is** — one paragraph, screenshot/gif
2. **Install** — `fisher install <repo>`, then soft-dep install commands
3. **Keybindings** — table of all binds (checkout, PR, Jira, preview, rebase, delete, refresh)
4. **Configuration** — the config file table above
5. **Requirements** — hard vs soft dep table
6. **Theming** — how to override `CORAL_COLOR_*` for non-Catppuccin themes
7. **Worktree support** — brief note on how linked worktrees are detected
8. **Jira integration** — set `CORAL_JIRA_URL_TEMPLATE`, branch naming convention

---

## Future enhancements

- Add `completions/coral.fish` for switches/subcommands such as `--doctor`, `clear-cache`, and `version`.
- Expand fishtape tests for branch filtering, fallback paths, doctor output, Slack output, and PR response fixtures.
- Add a soft refresh vs hard refresh split: soft reload keeps PR cache, hard reload clears and refetches PR metadata.
- Make label badge colors configurable, either globally or by label name.
- Consider an optional GraphQL or `gh api` PR lookup backend if branch-scoped `gh pr list --head` becomes too slow in very large local branch sets.
- Add a stale-cache indicator in the list or preview when PR data is older than the configured TTL.
- Add explicit support for non-GitHub remotes by hiding GitHub-only actions cleanly.
- Revisit `CORAL_BASE_BRANCHES` as a fish list variable instead of an ERE string.

---

## Open questions before publishing

- [ ] Does the plugin need a `completions/coral.fish` for argument completion?
- [ ] Should `CORAL_BASE_BRANCHES` use a list var (`set -gx CORAL_BASE_BRANCHES develop main`) instead of an ERE string? More fish-idiomatic.
- [x] The Jira key pattern is configurable via `CORAL_JIRA_KEY_PATTERN`; default is `[A-Z]+-[0-9]+`.
- [ ] Test on fish 3.3, 3.4, 3.6 — `set -f` (function-local) was introduced in 3.1; `wait` for background jobs in 3.1. Minimum should be confirmed.
- [ ] Decide whether to ship a default `CORAL_BASE_BRANCHES` that also matches `trunk` and `staging`.
