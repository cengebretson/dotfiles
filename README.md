# 🅃🄷🄴🅁🄴 🄸🅂 🄽🄾 🄿🄻🄰🄲🄴 🄻🄸🄺🄴 ~

[![Neovim](https://img.shields.io/badge/Neovim-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/) [![Ghostty](https://img.shields.io/badge/Ghostty-333333?style=for-the-badge&logo=windowsterminal&logoColor=white)](https://ghostty.org/) [![Fish Shell](https://img.shields.io/badge/Fish%20Shell-00A1D6?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://fishshell.com/) [![Lazygit](https://img.shields.io/badge/Lazygit-FC6D26?style=for-the-badge&logo=git&logoColor=white)](https://github.com/jesseduffield/lazygit) [![Superfile](https://img.shields.io/badge/Superfile-000000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/yorukot/superfile) [![Mise](https://img.shields.io/badge/Mise-000000?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyQzYuNDggMiAyIDYuNDggMiAxMnM0LjQ4IDEwIDEwIDEwIDEwLTQuNDggMTAtMTBTMTcuNTIgMiAxMiAyem0tMiAxNWwtNS01IDEuNDEtMS40MUwxMCAxNC4xN2w3LjU5LTcuNTlMMTkgOGwtOSA5eiIvPjwvc3ZnPg==&logoColor=white)](https://mise.jdx.dev/)

---

A curated collection of tools and configs that power my daily workflow.
#### 🌀 Lazygit

 * A simple, fast, and powerful Git UI for the terminal.

#### 🐟 Fish Shell

 * My interactive shell for a smooth terminal experience, with fzf wired in for fuzzy finding and bat-powered previews.

#### 👻 Ghostty

 * My terminal of choice — modern, GPU-accelerated, and lightning fast.
 * Run `ghostty-help` for a searchable fzf picker of all Ghostty actions and their keybindings.

#### 📟 Tmux

 * Terminal multiplexer with dual Catppuccin themes, custom status bar, and Neovim-friendly keybindings. See [tmux config](.config/tmux/README.md).

#### 📝 Neovim

 * My main editor — lightweight yet powerful. See [nvim-v12](.config/nvim-v12/README.md) for my custom 0.12 config built on the native `vim.pack` plugin manager.

#### 📂 Superfile

 * A modern, terminal file manager.

#### 🛠 Mise

 * Runtime version manager for Node, Bun, Python, and uv. Replaces Volta and pyenv with a single tool, with per-project version pinning via `.mise.toml`.

#### 💻 Fastfetch

 * For showing off system info in style — with random ASCII art and a pacman color row.

---

### ⌨️ CLI Reference

#### Fish Shortcuts

 | Key | Action |
 |-----|--------|
 | `→` / `ctrl+f` | Accept autosuggestion |
 | `⌥+→` | Accept one word of autosuggestion |
 | `⌥+e` | Edit current command in `$EDITOR` |
 | `⌥+s` | Prepend `sudo` to current command |
 | `ctrl+u` / `ctrl+k` | Delete to beginning / end of line |
 | `⌥+backspace` | Delete previous word |
 | `ctrl+r` | Fuzzy search shell history |
 | `ctrl+t` | Fuzzy search files and directories |
 | `ctrl+⌥+p` | Fuzzy search running processes |
 | `ctrl+⌥+l` | Fuzzy search git log |
 | `ctrl+⌥+s` | Fuzzy search git status |

#### Functions & Aliases

 | Command | Description |
 |---------|-------------|
 | `j <dir>` | Smart directory jump (zoxide) |
 | `ji` | Interactive zoxide picker |
 | `tldrf` | Fuzzy search tldr pages |
 | `kp` | Kill a process via fzf picker |
 | `dots` | Shorthand for dotfiles git commands |
 | `l` / `ll` / `la` | eza listings with icons and git status |
 | `lt` / `ltd` | eza tree views (files / directories) |

---

### 📦 Installation

Note to future self.....

- Run the following command — it handles everything (Xcode tools, Homebrew, dotfiles, packages, fish, mise runtimes, and macOS defaults)

```bash
curl https://raw.githubusercontent.com/cengebretson/dotfiles/master/.config/setup.sh | bash
```

- Open Neovim — plugins, LSP servers, and tools all install automatically on first launch

---

### Gallery

<img width="1258" height="859" alt="Screenshot 2025-10-29 at 10 59 10 PM" src="https://github.com/user-attachments/assets/2af07b3e-fe62-47bf-850e-533a8ae1ae53" />

---

### Inspiration

Many of the ideas for the tmux/nvim setup were inspired by discussions in the following repositories…
* https://github.com/catppuccin/tmux/discussions/317
* https://github.com/89iuv/dotfiles

---

[![Last Commit](https://img.shields.io/github/last-commit/cengebretson/dotfiles?style=for-the-badge&color=green)](https://github.com/cengebretson/dotfiles)
