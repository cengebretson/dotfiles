# nvim-v12

A Neovim 0.12 configuration built around the **native `vim.pack` plugin manager** — no lazy.nvim, no packer. The name reflects tight coupling to Neovim 0.12's new APIs.

## Requirements

- Neovim 0.12+
- `cargo` on PATH (for `blink.cmp` Rust build step)
- `fish_indent` (bundled with Fish shell)
- A Nerd Font terminal

## Plugin Management

Plugins are declared in `lua/plugins/init.lua` using `vim.pack.add()` and pinned via `nvim-pack-lock.json` (SHA lockfile).

```
:Pack sync    — install/update all plugins
:Pack status  — show install path
```

Install path: `~/.local/share/nvim/pack/nvim-v12/start/`


## Notable Features

### Dashboard with Random Image

The dashboard picks a random image from `assets/` on each launch — currently a series of Uncle Iroh paintings. The image renders inline via Kitty/iTerm protocol using snacks.image, scaled to `1.5x` of its natural fit-to-columns size.

### Custom Statuscolumn

A hand-rolled statuscolumn (`options.lua`) that:
- Displays absolute line numbers left-aligned and **bold** on the current line (using `CursorLineNr`)
- Displays relative numbers right-aligned on all other lines
- Integrates with snacks' sign cache for git/diagnostic/mark icons
- Keeps snacks' fold-click handler working

### System Clipboard by Default

`vim.o.clipboard = "unnamedplus"` — yanks go to the system clipboard automatically.

The `d`/`D` keys send to the black hole register (`"_d`) so deleting doesn't clobber the clipboard. Use `<leader>d` to delete *to* the clipboard when you actually want that.

### Treesitter Incremental Selection

`<CR>` in normal mode selects the node under the cursor. `<CR>` in visual mode expands to the parent node. `<BS>` in visual mode shrinks back. No plugin — uses `vim.treesitter` directly.

### Claude Code tmux Integration

Send code directly to a Claude Code pane running in the same tmux session — no copy/paste needed. See [Claude keymaps](#claude-code) below. Disable the bell notification with `vim.g.claude_bell = false`.

### Python Development

- **basedpyright** for type checking and completions with automatic venv detection (`.venv`, `venv`, `env`, `.env`)
- **ruff** as both LSP (inline linting) and formatter
- **neotest-python** for pytest integration
- **debugpy** via DAP for breakpoint debugging

### TypeScript / Bun Development

- **ts_ls** for TypeScript LSP
- **neotest-jest** + custom Bun adapter for test running
- **js-debug-adapter** for Node, TypeScript (tsx), Bun (`--inspect-brk`), and Chrome debugging

### Bun Test Support

Custom neotest adapter detects Bun projects via `bun.lock`/`bun.lockb` and runs `bun test <file>` (positional argument, not `--testPathPattern`).

### LSP Status in Statusline

The lualine `y` section shows live LSP progress (`vim.lsp.status()`) while operations are running, then falls back to showing active client names. Uses the native `LspProgress` autocmd — no plugin required.

### Snacks Indent Guides

Vertical indent guides (`│`) with scope highlighting for the current block. Animation disabled for performance.

### Oil File Explorer

Git-aware file explorer with:
- `gd` — toggle detail view (permissions, size, mtime)
- `g.` — toggle hidden files
- `git_status` column showing `M`/`A`/`D`/`?` per file
- Winbar showing current directory path
- Gitignored files hidden, git-tracked dotfiles shown

## Key Mappings

### Navigation

| Key | Action |
|-----|--------|
| `s` | Flash jump |
| `S` | Flash treesitter select |
| `<CR>` | Select treesitter node (normal) / expand (visual) |
| `<BS>` | Shrink treesitter selection (visual) |
| `<C-h/j/k/l>` | Navigate splits |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `<C-d>` / `<C-u>` | Scroll half-page (cursor centered) |
| `n` / `N` | Search next/prev (cursor centered) |

### Files & Search (snacks picker)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fr` | Recent files |
| `<leader>fs` | LSP symbols |
| `<leader>fd` | Diagnostics |
| `<leader>fk` | Keymaps |
| `<leader>fp` | Projects |
| `<leader><leader>` | Buffers (quick) |
| `-` | Open Oil file explorer |

### Git

| Key | Action |
|-----|--------|
| `<leader>gl` | Lazygit |
| `<leader>gf` | Lazygit file log |
| `<leader>gb` | Blame line (float) |
| `<leader>gB` | Toggle inline blame virtualtext |
| `<leader>gp` | Preview hunk |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gd` | Diff this |
| `]h` / `[h` | Next / prev hunk |

### LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | References |
| `gi` | Implementation |
| `K` | Hover docs |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |
| `<leader>D` | Type definition |
| `]d` / `[d` | Next / prev diagnostic |
| `<leader>e` | Show diagnostic float |

### Editing

| Key | Action |
|-----|--------|
| `d` / `D` | Delete to black hole (clipboard safe) |
| `<leader>d` | Delete to clipboard |
| `p` (visual) | Paste, keep clipboard (`"_dP`) |
| `<leader>p` (visual) | Paste from `+` register |
| `<A-j>` / `<A-k>` | Move line/selection up or down |
| `J` / `K` (visual) | Move selection up or down |
| `<leader>o` / `<leader>O` | Add blank line below/above |
| `jk` | Exit insert mode |
| `<leader>ts` | Toggle spell check |

### Quickfix

| Key | Action |
|-----|--------|
| `]q` / `[q` | Next / prev (wraps around) |
| `]Q` / `[Q` | Last / first |
| `<leader>xq` | Toggle quickfix window |

### Window & Buffer

| Key | Action |
|-----|--------|
| `<leader>sv` | Split vertical |
| `<leader>sh` | Split horizontal |
| `<leader>bd` | Delete buffer |
| `<leader>q` | Close window |
| `<C-/>` | Toggle terminal |

### Flash Operator-Pending

| Key | Action |
|-----|--------|
| `r` | Flash remote (operate on a remote location) |
| `R` | Flash treesitter search (operator + visual) |

### Tests (neotest)

| Key | Action |
|-----|--------|
| `<leader>tt` | Run nearest test |
| `<leader>tf` | Run file |
| `<leader>ts` | Run suite |
| `<leader>tl` | Run last |
| `<leader>tS` | Toggle summary |
| `<leader>to` | Open output |
| `<leader>tp` | Toggle output panel |
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
| `<leader>cq` | visual | Ask Claude about selection (sends code + prompt) |
| `<leader>cc` | normal | Ask Claude about current function/class |
| `<leader>cf` | normal | Ask Claude about current file |
| `<leader>cx` | normal | Send file diagnostics to Claude |
| `<leader>yf` | normal | Copy file path to clipboard |
| `<leader>yc` | visual | Copy selection with file:line context to clipboard |

### Copy Context (clipboard)

| Key | Action |
|-----|--------|
| `<leader>yf` | Copy file path |
| `<leader>yc` | Copy selection with file:line header (visual) |

## Format on Save

Configured via conform.nvim. Formatters by filetype:

| Filetype | Formatter |
|----------|-----------|
| Lua | stylua |
| JavaScript / TypeScript / Vue | prettierd → prettier |
| Java | google-java-format |
| Fish | fish_indent |
| Python | ruff |

## Mason-managed Tools

Installed automatically on first launch:

| Tool | Purpose |
|------|---------|
| `lua_ls` | Lua LSP |
| `basedpyright` | Python LSP (type checking) |
| `ruff` | Python LSP + formatter |
| `ts_ls` | TypeScript LSP |
| `vue_ls` | Vue LSP |
| `stylua` | Lua formatter |
| `shellcheck` | Shell script linter |
| `eslint_d` | JS/TS linter |
| `debugpy` | Python debugger |
| `js-debug-adapter` | JS/TS/Bun/Chrome debugger |

## Transparency

The catppuccin theme uses `#000000` as base for Ghostty terminal transparency. Floating windows use `winblend = 20`. `NormalFloat`, `FloatBorder`, `Pmenu` backgrounds are cleared to `NONE` on every colorscheme load.
