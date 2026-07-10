# nvim-v12

A Neovim 0.12 config built around the native **`vim.pack`** plugin manager — no lazy.nvim, no packer. The name reflects tight coupling to 0.12's new APIs.

Activated via `NVIM_APPNAME=nvim-v12`, exported in the fish config (`set -gx NVIM_APPNAME nvim-v12` in `~/.config/fish/config.fish`).

## Requirements

- Neovim 0.12+
- `cargo` on PATH (for the `blink.cmp` Rust build step)
- `fish_indent` (bundled with Fish)
- A Nerd Font terminal

## Plugin Management

Plugins are declared in `lua/plugins/init.lua` via `vim.pack.add()` and pinned per-spec with `version`/`tag` (e.g. `blink.cmp` → `tag = "v1.*"`). Install path: `~/.local/share/nvim-v12/site/pack/core/opt/`.

| Command | Key | Action |
|---------|-----|--------|
| `:Pack sync` | `<leader>ps` | Fetch + review/apply updates (`:write` applies, `:quit` discards) |
| `:Pack outdated` | `<leader>po` | Same native preview, just to see what's outdated |
| `:Pack status` | `<leader>pt` | List installed plugins + revisions (floating window) |
| `:Pack clean` | `<leader>pr` | Remove orphaned plugins (with confirmation) |

## Notable Features

- **Dashboard** — random image from `assets/` each launch (Uncle Iroh paintings), rendered inline via the Kitty/iTerm protocol (snacks.image) at 1.5× fit-to-columns. Auto-hides/restores around the `:Pack sync` screen.
- **Custom statuscolumn** (`options.lua`) — bold absolute number on the current line, relative numbers elsewhere, snacks sign/fold integration.
- **System clipboard by default** — `clipboard=unnamedplus`. `d`/`D` go to the black-hole register so deletes don't clobber the clipboard; use `<leader>d` to delete *to* it.
- **Treesitter incremental selection** — `<CR>`/`<BS>` to grow/shrink the selection, no plugin (uses `vim.treesitter`).
- **Claude Code tmux integration** — send code to a Claude pane in the same tmux session; see [Claude keymaps](#claude-code). Disable the bell with `vim.g.claude_bell = false`.
- **Comment-header dividers** — `<leader>ch` inserts a commented `── Header ─────` rule padded to 80 cols, using the buffer's commentstring.
- **LSP status in statusline** — lualine `y` section shows live `vim.lsp.status()` progress, then active client names. Native `LspProgress` autocmd, no plugin.
- **Oil file explorer** — git-aware; `gd` toggles detail view, `g.` toggles hidden files, git-status column, dir winbar. Gitignored hidden, tracked dotfiles shown.
- **Snacks indent guides** — `│` with scope highlighting, animation off for performance.
- **Transparency** — catppuccin on `#000000` base for Ghostty; floats at `winblend=10`; `NormalFloat`/`FloatBorder`/`Pmenu` backgrounds cleared on every colorscheme load.

### Language Support

- **Python** — basedpyright (type-checking, auto venv detection: `.venv`/`venv`/`env`/`.env`), ruff (LSP + formatter), neotest-python, debugpy.
- **TypeScript / Bun** — ts_ls, neotest-jest + a custom Bun adapter (detects `bun.lock`/`bun.lockb`, runs `bun test <file>`), js-debug-adapter for Node/tsx/Bun/Chrome.

## Key Mappings

Leader is `<space>`.

### General

| Key | Action |
|-----|--------|
| `<leader>w` / `<C-s>` (insert) | Save file |
| `;` | Command mode (`:`) |
| `<Esc>` | Clear search highlight |
| `jk` (insert) | Exit insert mode |

### Navigation

| Key | Action |
|-----|--------|
| `s` / `S` | Flash jump / Flash treesitter select |
| `<CR>` / `<BS>` | Grow / shrink treesitter selection |
| `<C-h/j/k/l>` | Navigate splits |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `<C-d>` / `<C-u>` | Scroll half-page (centered) |
| `n` / `N` | Search next / prev (centered) |
| `*` / `#` | Search word under cursor (centered) |

### Files & Search (snacks picker)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` / `<leader><leader>` | Buffers |
| `<leader>fr` | Recent files |
| `<leader>fs` | LSP symbols |
| `<leader>fd` | Diagnostics |
| `<leader>fk` | Keymaps |
| `<leader>fp` | Projects |
| `<leader>ft` | Find TODOs |
| `<leader>fD` | Open dashboard |
| `-` | Open Oil file explorer |

### LSP & Code

| Key | Action |
|-----|--------|
| `gd` / `gr` / `gi` | Definition / references / implementation |
| `K` | Hover docs |
| `<leader>k` / `<C-k>` (insert) | Signature help |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |
| `<leader>D` | Type definition |
| `<leader>=` | Format file or range (conform) |
| `<leader>rF` | Ruff fix (Python) |
| `<leader>e` | Show diagnostic float |
| `]d` / `[d` | Next / prev diagnostic (Trouble) |

### Editing

| Key | Action |
|-----|--------|
| `d` / `D` | Delete to black hole (clipboard-safe) |
| `<leader>d` | Delete to clipboard |
| `p` (visual) | Paste, keep clipboard |
| `<leader>p` (visual) | Paste from `+` register |
| `<A-j>` / `<A-k>` | Move line / selection down or up |
| `J` / `K` (visual) | Move selection down / up |
| `J` (normal) | Join lines, keep cursor |
| `<leader>o` / `<leader>O` | Blank line below / above |
| `<leader>us` | Toggle spell check |

### Windows & Buffers

| Key | Action |
|-----|--------|
| `<leader>sv` / `<leader>sh` | Split vertical / horizontal |
| `<C-Up/Down/Left/Right>` | Resize split |
| `<leader>bd` | Delete buffer |
| `<leader>q` | Close window |
| `<C-/>` | Toggle terminal |

### Version Control

| Key | Action |
|-----|--------|
| `<leader>vl` / `<leader>vf` | Lazygit / Lazygit file log |
| `<leader>vb` / `<leader>vB` | Blame line / toggle inline blame |
| `<leader>vp` / `<leader>vs` / `<leader>vr` | Preview / stage / reset hunk |
| `]h` / `[h` | Next / prev hunk |
| `<leader>vd` | Diff this (gitsigns) |
| `<leader>vD` | Diffview open |
| `<leader>vh` / `<leader>vH` | Diffview file / repo history |
| `<leader>vx` | Diffview close |

### Flash (operator-pending)

| Key | Action |
|-----|--------|
| `r` | Flash remote (operate on a remote location) |
| `R` | Flash treesitter search (operator + visual) |

### Trouble & TODOs

| Key | Action |
|-----|--------|
| `<leader>xx` | Workspace diagnostics |
| `<leader>xd` | Document diagnostics |
| `<leader>xe` | Errors only |
| `<leader>xs` | Symbols |
| `<leader>xl` / `<leader>xL` | LSP references / location list |
| `<leader>xt` | TODOs |
| `<leader>xq` | Quickfix list |
| `]t` / `[t` | Next / prev TODO |

### Quickfix

| Key | Action |
|-----|--------|
| `]q` / `[q` | Next / prev (wraps) |
| `]Q` / `[Q` | Last / first |
| `<leader>xq` | Toggle quickfix window |

### Tests (neotest)

| Key | Action |
|-----|--------|
| `<leader>tt` / `<leader>tf` / `<leader>ts` | Run nearest / file / suite |
| `<leader>tl` | Run last |
| `<leader>tS` | Toggle summary |
| `<leader>to` / `<leader>tp` | Open output / toggle panel |
| `<leader>tx` | Trouble: neotest results |
| `]n` / `[n` | Next / prev failed test |

### Debug (DAP)

| Key | Action |
|-----|--------|
| `<F5>` / `<leader>dc` | Continue / start |
| `<F9>` / `<leader>db` | Toggle breakpoint |
| `<F10>` / `<leader>do` | Step over |
| `<F11>` / `<leader>di` | Step into |
| `<F12>` / `<leader>dO` | Step out |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dq` | Terminate |
| `<leader>du` | Toggle DAP UI |
| `<leader>de` | Eval expression |

### Claude Code

| Key | Mode | Action |
|-----|------|--------|
| `<leader>cq` | visual | Ask about selection (code + prompt) |
| `<leader>cc` | normal | Ask about current function/class |
| `<leader>cl` | normal | Ask about current line |
| `<leader>cf` | normal | Ask about current file |
| `<leader>cx` | normal | Send file diagnostics |

## Format on Save (conform.nvim)

| Filetype | Formatter |
|----------|-----------|
| Lua | stylua |
| JS / TS / Vue | biome → prettierd → prettier |
| Go | goimports → gofumpt |
| Python | ruff |
| Java | google-java-format |
| Fish | fish_indent |

## Mason-managed Tools

Installed on first launch: `lua_ls`, `basedpyright`, `ruff`, `ts_ls`, `vue_ls`, `cssls`, `gopls`, `bashls` (LSPs); `biome`, `stylua`, `prettierd`, `goimports`, `gofumpt` (formatters); `shellcheck` (linter); `debugpy`, `js-debug-adapter` (debuggers).
