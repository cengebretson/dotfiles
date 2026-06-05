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
| `functions/coral.spec.md` | Coral function/plugin design notes |
| `secrets.fish` | Machine-local secrets, not for public docs |

## Fisher Plugins

Install additive plugins with `fisher install <owner/repo>`. Use `fisher update` only after `fish_plugins` is correct, because Fisher treats that file as the desired manifest.

Current manifest:

| Plugin | Purpose |
|--------|---------|
| `PatrickF1/fzf.fish` | fzf key bindings and helper functions |
| `patrickf1/colored_man_pages.fish` | Colored man pages |
| `danhper/fish-ssh-agent` | SSH agent startup |
| `jorgebucaran/autopair.fish` | Paired character insertion |
| `reitzig/sdkman-for-fish@v1.4.0` | SDKMAN integration |
| `jorgebucaran/fisher` | Fish plugin manager |
| `nickeb96/puffer-fish` | Shell expansion helpers |
| `icezyclon/zoxide.fish` | zoxide Fish integration |
| `jorgebucaran/fishtape` | Fish test runner |

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

## Custom Functions

These live in `functions/` and are not Fisher-managed.

| Command | Purpose |
|---------|---------|
| `claude` | Run Claude Code and rename the tmux window to `claude` while active |
| `confetti` | Trigger the Raycast confetti extension |
| `coral` | Browse local Git branches with fzf, PR status, previews, and branch actions |
| `fish_greeting` | Show a custom shell greeting with random image/system info |
| `keychain` | List macOS Keychain entries or set an environment variable from a Keychain value |
| `kp` | Kill processes selected with fzf |
| `ports` | List listening TCP ports, filter by port, or stop a listener |
| `pr` | Open the current branch's GitHub PR in the browser |
| `speed` | Run macOS `networkQuality` with simple, watch, upload, download, and verbose modes |

## Coral

`coral` is a local Fish function suite, not a Fisher plugin yet. Its runtime config lives at:

```text
~/.config/coral/config.fish
```

Its local tests currently live at:

```text
~/.config/coral/tests/
```

Run them with:

```fish
fishtape ~/.config/coral/tests/*.test.fish
```

See `functions/coral.spec.md` for the design notes, dependency contract, config keys, and test expectations.
