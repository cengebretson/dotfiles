# Fish Shell

Interactive shell config, Fisher-managed plugins, and custom helper functions.

## Files

| Path | Purpose |
|------|---------|
| `config.fish` | Main interactive shell setup |
| `alias.fish` | Aliases and shorthand commands |
| `fish_plugins` | Fisher plugin manifest |
| `conf.d/` | Auto-sourced startup snippets |
| `functions/` | Autoloaded Fish functions |
| `secrets.fish` | Machine-local secrets, not for public docs |

## Fisher Plugins

Install additive plugins with `fisher install <owner/repo>`. Use `fisher update` only after `fish_plugins` is correct, because Fisher treats that file as the desired manifest.

Current manifest:

| Plugin | Purpose |
|--------|---------|
| `PatrickF1/fzf.fish` | fzf key bindings and helper functions |
| `patrickf1/colored_man_pages.fish` | Colored man pages — provides the `cless` and `man` functions in `functions/` |
| `danhper/fish-ssh-agent` | SSH agent startup |
| `jorgebucaran/autopair.fish` | Paired character insertion |
| `jorgebucaran/fisher` | Fish plugin manager |
| `nickeb96/puffer-fish` | Shell expansion helpers |
| `icezyclon/zoxide.fish` | zoxide Fish integration |
| `jorgebucaran/fishtape` | Fish test runner |
| `cengebretson/coral` | Local-branch browser with fzf, PR status & branch actions |

## Shortcuts

| Key | Action |
|-----|--------|
| `->` / `ctrl+f` | Accept autosuggestion |
| `option+->` | Accept one word of autosuggestion |
| `option+e` | Edit current command in `$EDITOR` |
| `option+s` | Prepend `sudo` to current command |
| `ctrl+u` / `ctrl+k` | Delete to beginning / end of line |
| `option+backspace` | Delete previous word |
| `ctrl+r` | Fuzzy search shell history |
| `ctrl+t` | Fuzzy search files and directories |
| `ctrl+p` | Fuzzy search running processes |
| `ctrl+option+l` | Fuzzy search git log |
| `ctrl+option+s` | Fuzzy search git status |

## Aliases & Abbreviations

Defined in `alias.fish`, `config.fish`, and custom functions. Highlights:

| Command | Expands to |
|---------|-----------|
| `j <dir>` / `ji` | zoxide smart jump / interactive picker |
| `l` / `ll` / `la` | eza listings (compact / long+git / long by mtime) |
| `lt` / `ltd` | eza tree view (all files / directories only) |
| `dots` | `git --git-dir=$HOME/.dotfiles --work-tree=$HOME` (abbr, expands anywhere) |
| `dots-status` | dotfiles status with untracked files forced visible |
| `dots-untracked` | list untracked files visible to the bare dotfiles repo |
| `zz` | the `~/.config/fish/config.fish` path (abbr) |
| `cat` / `find` / `vi`,`vim` | `bat` / `fd` / `nvim` |
| `o` / `oo` | `open` / `open .` |
| `reload` | `exec fish` |
| `updates` | brew update + upgrade + bundle install + tmux TPM plugins + Fisher plugins + completions + mise upgrade/prune + cleanup |
| `gcopy` | copy short HEAD SHA to clipboard |
| `ipl` / `ipx` | local IP (en0) / external IP |
| `flush` | flush macOS DNS cache |
| `weather` / `moon` | wttr.in forecast / moon phase |

## Custom Functions

These live in `functions/` and are not Fisher-managed.

| Command | Purpose |
|---------|---------|
| `claude` | Run Claude Code and rename the tmux window to `claude` while active |
| `codex` | Run Codex and rename the tmux window to `codex` while active |
| `confetti` | Trigger the Raycast confetti extension |
| `fish_greeting` | Show a custom shell greeting with random image/system info |
| `keychain` | List, add, or delete macOS Keychain internet-password entries, or export one into an environment variable (`setenv`) |
| `kp` | Kill processes selected with fzf |
| `ports` | List listening TCP ports, filter by port, or stop a listener |
| `speed` | Run macOS `networkQuality` with simple, watch, upload, download, and verbose modes |
| `pr-report` | List your open PRs with CI/review status, unresolved Copilot/human threads, Jira status, and labels; `--json`, `--slack`, `--short` output modes plus include/exclude term filtering |
| `tmux-attention` | Interactive convenience wrapper to set/clear the per-window `@agent_attention` marker in tmux (bell fallback outside tmux). Agent hooks do not use this function — they call the tmux-attention plugin CLI (`~/.config/tmux/plugins/tmux-attention/scripts/tmux-attention`) via hook handlers |
| `moshi-notify` | Toggle/inspect Moshi agent-hook notifications: `off`/`on`/`toggle`/`status` (bound to `prefix N` in tmux) |
| `phoneview` | Create grouped tmux session mirrors (`phone-<name>`) for the phone to attach to without clobbering the laptop view; `phoneview all`/`<name>`/`clean` |
| `rtmux` | Pick and attach to a tmux session on an online Tailscale peer via fzf. Username is resolved per host from your ssh config (so a `User` directive in `~/.ssh/config.local` is honored); `-u <user>` forces one user for all hosts. `--doctor` diagnoses connectivity. Falls back to `TERM=xterm-256color` on hosts lacking the local terminfo. (peer helper: `_rtmux_peers`) |

## Custom Completions

Tracked completions under `completions/` (most others are Fisher-managed and not tracked).

| File | Purpose |
|------|---------|
| `tailscale.fish` | Sources tailscale's generated subcommand/flag completion, plus dynamic value completion it lacks: Taildrop targets for `file cp` (own devices + trailing colon), host arg for `ping`/`ip`, and `--exit-node=` values for `set`/`up` (exit nodes labelled by country/city) |

## Coral

`coral` is now published as a Fisher plugin — [`cengebretson/coral`](https://github.com/cengebretson/coral). Its functions, completions, and `conf.d` setup are Fisher-managed (installed under `functions/`, `completions/`, `conf.d/`), so they are **not tracked** in these dotfiles.

Runtime config lives at:

```text
~/.config/coral/config.fish
```

Run `coral --doctor` for dependency, config, repo, cache, and GitHub-auth diagnostics. Source and tests live in the plugin repo.
