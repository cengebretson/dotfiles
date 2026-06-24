# Tmux Config

A customized tmux setup built around [Catppuccin](https://github.com/catppuccin/tmux) with dual themes, a custom status bar, and Neovim-friendly keybindings.

## Key Bindings

| Key | Action |
|-----|--------|
| `C-Space` | Prefix |
| `prefix + j` | Pane/window switcher (fzf popup) |
| `prefix + r` | Reload config |
| `prefix + \|` | Split horizontal (current path) |
| `prefix + -` | Split vertical (current path) |
| `prefix + T` | Toggle theme |
| `prefix + y` | Lazygit popup |
| `prefix + c` | New window (with name prompt) |
| `prefix + S` | New session (with name prompt) |
| `prefix + N` | Toggle Moshi notifications (daemon off/on) |
| `Option + h/l` | Previous / next window |
| `Ctrl + h/j/k/l` | Navigate panes (vim-tmux-navigator) |
| `C-k` | Which-key menu |

Copy mode uses vi keys — `v` to select, `C-v` for rectangle, `y` to yank to system clipboard, `Escape` to exit. A `󰆏 COPY` indicator appears in the status bar while in copy mode. Search match highlights use Catppuccin mauve.

## Dual Theme System

Two themes are available and toggled with `prefix + T`:

- **appearance1.conf** — centered window list, solid background, online/battery/path modules
- **appearance2.conf** — left-aligned window list, mocha theme, path/CPU/RAM modules

`appearance.conf` is a symlink pointing to whichever is active. `toggle_theme.sh` swaps the symlink and reloads the config.

Both themes use custom status modules and window text formats.

## Status Bar

**Left:** prefix indicator, session name

**Right (appearance2):** current path, CPU%, RAM%, Moshi daemon indicator (`󰄛`)

The Moshi `󰄛` indicator is present in both themes (see the Moshi section below).

Window tabs use custom Unicode number glyphs via `custom_number.sh`. The active window uses filled square glyphs; inactive windows use double-stroke squares.

## Bell Notifications

When a background window receives a bell alert, a `󰂞` icon appears in red in its window tab. This is implemented via `#{?window_bell_flag,...}` directly in the window text format rather than relying on catppuccin's flag system, which doesn't apply with custom window status style.

`window-status-bell-style` is set to `none` after tpm initializes (catppuccin overrides it during plugin load, so it must be set last in `tmux.conf`).

## Moshi Remote / Phone Sessions

Integration for driving agents from the phone over the Moshi app (mosh + tmux). Full design lives in `~/workspace/plans/moshi-remote-agent-setup.md`.

- **Daemon indicator (`moshi_status.sh`):** a 3-state `󰄛` glyph in the status bar. Dim "off" means the moshi-hook daemon is stopped; amber "on" means running but unpaired (no pushes); green "on" means running and paired. Daemon state is read with `pgrep` each refresh; pairing is cached in the `@moshi_paired` user option (seeded on load in `tmux.conf`, refreshed by `moshi-notify`) because querying it touches the Keychain.
- **`prefix + N`:** toggles the daemon off/on via the `moshi-notify` fish function, run through a login fish and backgrounded since `brew services stop` can be slow.
- **Phone auto-view (`phone_autoview.sh`, `phone_autoview_cleanup.sh`):** a `client-attached` hook detects a narrow (phone) client by terminal width and moves it onto a grouped `phone-<session>` mirror, so the phone shares your windows at its own size without reshaping the laptop view. A `client-detached` hook reaps the mirror when the phone leaves. Both hooks append (`set-hook -ga`) and are guarded against duplicate registration on reload, preserving the tmux-attention hooks.
- **Hiding mirrors from the picker:** `@fzf_pane_switch_exclude-sessions "phone-*"` keeps the ephemeral mirror sessions out of the fzf-jump list. The plugin filter is generic; the `phone-*` value is set here in `tmux.conf`.

## Plugins

- `tmux-plugins/tpm` — plugin manager
- `tmux-plugins/tmux-sensible` — sane defaults
- `tmux-plugins/tmux-battery` — battery status
- `tmux-plugins/tmux-cpu` — CPU/RAM stats
- `tmux-plugins/tmux-online-status` — network status
- `catppuccin/tmux` — theme framework
- `christoomey/vim-tmux-navigator` — seamless pane/split navigation with Neovim
- `cengebretson/tmux-which-key` — which-key menu

## Version Notes

- tmux 3.6: `display-popup` height **percentages** (`-h 10%`) do not render correctly — use fixed line counts (`-h 3`) instead. Width percentages (`-w 40%`) work fine.
