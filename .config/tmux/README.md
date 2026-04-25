# Tmux Config

A customized tmux setup built around [Catppuccin](https://github.com/catppuccin/tmux) with dual themes, a custom status bar, and Neovim-friendly keybindings.

## Key Bindings

| Key | Action |
|-----|--------|
| `C-Space` | Prefix |
| `C-Space` (hold) | Window switcher (fzf popup) |
| `prefix + r` | Reload config |
| `prefix + \|` | Split horizontal (current path) |
| `prefix + -` | Split vertical (current path) |
| `prefix + T` | Toggle theme |
| `prefix + y` | Lazygit popup |
| `prefix + C-n` | New session popup |
| `prefix + d` | Dotfiles menu |
| `Option + h/l` | Previous / next window |
| `Ctrl + h/j/k/l` | Navigate panes (vim-tmux-navigator) |
| `C-k` | Which-key menu |

Copy mode uses vi keys — `v` to select, `C-v` for rectangle, `y` to yank.

## Dual Theme System

Two themes are available and toggled with `prefix + T`:

- **appearance1.conf** — centered window list, solid bg, block-style active window separators
- **appearance2.conf** — left-aligned, transparent bg, custom inline separators

`appearance.conf` is a symlink pointing to whichever is active. `toggle_theme.sh` swaps the symlink and reloads the config.

Both themes share the same status bar modules and window text format.

## Status Bar

**Left:** prefix indicator, session name

**Right (appearance2):** current path, CPU%, RAM%, battery

Window tabs use custom Unicode number glyphs via `custom_number.sh`. The active window uses filled square glyphs; inactive windows use double-stroke squares.

## Bell Notifications

When a background window receives a bell alert, a `󰂞` icon appears in red in its window tab. This is implemented via `#{?window_bell_flag,...}` directly in the window text format rather than relying on catppuccin's flag system, which doesn't apply with custom window status style.

`window-status-bell-style` is set to `none` after tpm initializes (catppuccin overrides it during plugin load, so it must be set last in `tmux.conf`).

## Plugins

- `tmux-plugins/tpm` — plugin manager
- `tmux-plugins/tmux-sensible` — sane defaults
- `tmux-plugins/tmux-battery` — battery status
- `tmux-plugins/tmux-cpu` — CPU/RAM stats
- `tmux-plugins/tmux-online-status` — network status
- `catppuccin/tmux` — theme framework
- `christoomey/vim-tmux-navigator` — seamless pane/split navigation with Neovim
- `cengebretson/tmux-which-key` — which-key menu
