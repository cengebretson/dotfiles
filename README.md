# 🅃🄷🄴🅁🄴 🄸🅂 🄽🄾 🄿🄻🄰🄲🄴 🄻🄸🄺🄴 ~

[![Neovim](https://img.shields.io/badge/Neovim-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/) [![Ghostty](https://img.shields.io/badge/Ghostty-333333?style=for-the-badge&logo=windowsterminal&logoColor=white)](https://ghostty.org/) [![Fish Shell](https://img.shields.io/badge/Fish%20Shell-00A1D6?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://fishshell.com/) [![Lazygit](https://img.shields.io/badge/Lazygit-FC6D26?style=for-the-badge&logo=git&logoColor=white)](https://github.com/jesseduffield/lazygit) [![Superfile](https://img.shields.io/badge/Superfile-000000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/yorukot/superfile)
A curated collection of tools and configs that power my daily workflow.

#### 🌀 Lazygit

 * A simple, fast, and powerful Git UI for the terminal.

#### 🐟 Fish Shell

 * My interactive shell for a smooth terminal experience, with fzf wired in for fuzzy finding and bat-powered previews.

 **Shortcuts**

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

 **Functions & aliases**

 | Command | Description |
 |---------|-------------|
 | `j <dir>` | Smart directory jump (zoxide) |
 | `ji` | Interactive zoxide picker |
 | `tldrf` | Fuzzy search tldr pages |
 | `kp` | Kill a process via fzf picker |
 | `dots` | Shorthand for dotfiles git commands |
 | `l` / `ll` / `la` | eza listings with icons and git status |
 | `lt` / `ltd` | eza tree views (files / directories) |

#### 👻 Ghostty

 * My terminal of choice — modern, GPU-accelerated, and lightning fast.
 * Run `ghostty-help` for a searchable fzf picker of all Ghostty actions and their keybindings.

#### 📟 Tmux

 * Terminal multiplexer with dual Catppuccin themes, custom status bar, and Neovim-friendly keybindings. See [tmux config](.config/tmux/README.md).

#### 📝 Neovim

 * My main editor — lightweight yet powerful. See [nvim-v12](.config/nvim-v12/README.md) for my custom 0.12 config built on the native `vim.pack` plugin manager.

#### 📂 Superfile

 * A modern, terminal file manager.

#### 💻 Neofetch

 * For showing off system info in style.

---

### 📦 Installation

Note to future self.....

- Run the following command to install dotfiles and packages (using a bare git repo)

```bash
curl https://raw.githubusercontent.com/cengebretson/dotfiles/master/.config/setup.sh | bash
```

- Install applications using brew

```bash
brew bundle install --file=~/.config/Brewfile
```

- Run fish command for fish plugins

```bash
fisher update
```

- Run Lazy sync in neovim the first time starting up

```vim
Lazy sync
```

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
