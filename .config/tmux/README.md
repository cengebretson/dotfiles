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

`appearance.conf` is a symlink pointing to whichever is active. `scripts/toggle_theme.sh` swaps the symlink and reloads the config.

Both themes use custom status modules and window text formats.

## Status Bar

**Left:** prefix indicator, session name

**Right (appearance2):** remote-connection indicator (`󰚥`, when applicable), current path, CPU%, RAM%, Moshi daemon indicator (`󰄛`)

The Moshi `󰄛` indicator is present in both themes. On narrow clients (under `@phone_max_cols`, e.g. the phone) the bar collapses to a compact form: see the Moshi section.

A peach `󰚥 <host>` shows only when the attached client came in over SSH (i.e. the session is *remote*), and only on full-width clients. Detection is true SSH detection, not hostname: `scripts/conn_type.sh` reads `SSH_CONNECTION` (propagated via `update-environment`) on the `client-attached` / `client-session-changed` hooks and records it in the `@conn_type` option that the status bar reads. Nothing renders for local sessions.

Window tabs use custom Unicode number glyphs via `scripts/custom_number.sh`. The active window uses filled square glyphs; inactive windows use double-stroke squares.

## Bell Notifications

When a background window receives a bell alert, a `󰂞` icon appears in red in its window tab. This is implemented via `#{?window_bell_flag,...}` directly in the window text format rather than relying on catppuccin's flag system, which doesn't apply with custom window status style.

`window-status-bell-style` is set to `none` after tpm initializes (catppuccin overrides it during plugin load, so it must be set last in `tmux.conf`).

## Moshi Remote / Phone Sessions

Integration for driving agents (Claude, Codex) from the phone over the Moshi app (mosh + tmux + Tailscale). Helper scripts live in `scripts/`.

### Notifications

- **Daemon indicator + toggle ([`cengebretson/tmux-moshi`](https://github.com/cengebretson/tmux-moshi) plugin):** a 3-state `󰄛` glyph in the status bar — dim "off" (daemon stopped), amber "on" (running but unpaired), green "on" (running and paired). Spliced into the bar as `#{E:@moshi_status}` in `appearance1/2.conf`. Daemon state is read with `pgrep` each refresh; pairing is cached in `@moshi_paired` (seeded by the plugin, refreshed by `moshi-notify`) because querying it touches the Keychain.
- **`prefix + N`** (also left-click the glyph, or right-click for a menu): toggles the daemon off/on via the `moshi-notify` fish function (the plugin's `@moshi_toggle_command`), backgrounded since `brew services stop` can be slow. The indicator flips when it lands.

### Phone auto-view (no clobbering)

Two clients on one tmux session share the current window and shrink to the smaller screen. To stop the phone reshaping the laptop, a narrow client is moved onto its own grouped mirror:

> **Single threshold:** "narrow = phone" is defined once in `tmux.conf` as the `@phone_max_cols` option (currently `80`). Both this mirror logic (`phone_autoview.sh` reads the option, falling back to 80) and the responsive status bar (appearance2) read the same value, so there is no width band that gets phone chrome while still clobbering the laptop's view.

- **`scripts/phone_autoview.sh`** runs on both `client-attached` and `client-session-changed`. When a narrow client (terminal width under `@phone_max_cols`) lands on a real session, it is switched onto a grouped `phone-<session>` mirror that shares the windows but keeps its own size. The window the client landed on is preserved in the mirror.
- **`client-session-changed`** is what makes jumping safe: picking a session from fzf-jump fires it, so the phone is bounced onto the mirror instead of sitting directly on the real session (which would clobber the laptop).
- **`scripts/phone_autoview_cleanup.sh`** runs on `client-detached` and reaps any `phone-*` mirror with no clients, so the mirrors are ephemeral.
- Hooks append (`set-hook -ga`) and a `@phone_autoview_installed` guard prevents duplicate registration on reload, while preserving the tmux-attention hooks. Wide clients (the laptop) are never touched.

### Jumping from the phone

- fzf-jump (tap the status-left `󰐱` area, or `prefix + j` / `M-j`) shows your **normal** session names; the `phone-*` mirrors are hidden via `@fzf_pane_switch_exclude-sessions "phone-*"` (the plugin filter is generic; the value is set in `tmux.conf`).
- Selecting a session or window switches the phone there, and the `client-session-changed` hook immediately bounces it onto that session's mirror, so you always land on the iPhone-sized view.

### Responsive status bar (appearance2)

The status line is drawn per client, so it adapts to width via `#{e|>=:#{client_width},#{@phone_max_cols}}`. On clients under `@phone_max_cols` (the phone):

- status-right (path, CPU, RAM, the Moshi indicator) is hidden.
- the session name (`#S`) is dropped from status-left, since Moshi's picker already shows it; the prefix icon stays.
- window tabs show only their number glyph, not the name, so multiple windows fit.

The laptop (>= `@phone_max_cols`) keeps the full bar. Mouse mode is on, so on the phone you can tap panes and windows to focus, and swipe to scroll.

## Scripts

Helper scripts live in `scripts/`:

| Script | Purpose |
|---|---|
| `custom_number.sh` | Render window-index glyphs (filled / double-stroke squares) for the window tabs |
| `toggle_theme.sh` | Swap the `appearance.conf` symlink between themes and reload (`prefix + T`) |
| `phone_autoview.sh` | Redirect a narrow phone client onto a grouped `phone-<session>` mirror |
| `phone_autoview_cleanup.sh` | Reap unattached `phone-*` mirror sessions |
| `conn_type.sh` | Set `@conn_type` (`remote`/`local`) from the client's `SSH_CONNECTION` so the status bar can show a remote-connection indicator |

## Plugins

- `tmux-plugins/tpm` — plugin manager
- `tmux-plugins/tmux-sensible` — sane defaults
- `tmux-plugins/tmux-battery` — battery status
- `tmux-plugins/tmux-cpu` — CPU/RAM stats
- `tmux-plugins/tmux-online-status` — network status
- `catppuccin/tmux` — theme framework
- `christoomey/vim-tmux-navigator` — seamless pane/split navigation with Neovim
- `cengebretson/tmux-which-key` — which-key menu
- `cengebretson/tmux-fzf-jump` — fzf session/window/pane switcher (`prefix + j`), shows attention states and activity markers
- `cengebretson/tmux-attention` — per-window agent attention marker (`@agent_attention` state + tab icon); see `attention-marker.md`
- `cengebretson/tmux-moshi` — Moshi daemon indicator/toggle for the status bar (see the Moshi section)

## Version Notes

- tmux is currently 3.7b. On 3.6, `display-popup` height **percentages** (`-h 10%`) did not render correctly; this has not been retested on 3.7b, so fixed line counts (`-h 3`) remain the safe default. Width percentages (`-w 40%`) work fine.
