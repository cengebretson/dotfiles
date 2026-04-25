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

## Architecture

```
init.lua                     enables vim.loader, loads core.* and plugins
lua/
  core/
    options.lua              vim options, statuscolumn, clipboard, transparency
    keymaps.lua              global keymaps (leader = <Space>)
    colors.lua               color palette constants
  plugins/
    init.lua                 plugin declarations, Pack command, loader loop
    blink.lua                completion (blink.cmp, super-tab preset)
    conform.lua              format-on-save (stylua, prettierd, google-java-format, fish_indent)
    lsp.lua                  LSP via Mason + mason-lspconfig (automatic_enable = true)
    oil.lua                  file explorer replacing netrw (floating, - to open)
    themes.lua               catppuccin-mocha, transparent bg for Ghostty
    tree-sitter-manager.lua  treesitter grammars
    which-key.lua            key hint popups + leader group labels
    gitsigns.lua             git signs in gutter + hunk navigation
    snacks.lua               picker, dashboard, indent guides, lazygit, terminal
    noice.lua                UI replacements for cmdline and notifications
    flash.lua                jump/search navigation
    neotest.lua              test runner (Jest + Bun adapters)
    lualine.lua              statusline
    trouble.lua              diagnostics/quickfix list panel
    todo-comments.lua        TODO/FIXME highlighting
    diffview.lua             git diff viewer
    render-markdown.lua      in-buffer markdown rendering
    autopairs.lua            auto-close brackets and quotes
    surround.lua             surround text objects (nvim-surround)
assets/
  iroh*.png                  dashboard background images (Uncle Iroh art)
```

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

### Bun Test Support

`neotest.lua` includes a custom Bun adapter alongside neotest-jest. Detects Bun projects via `bun.lock`/`bun.lockb` and runs `bun test <file>` (positional argument, not `--testPathPattern`).

### LSP Status in Statusline

The lualine `y` section shows live LSP progress (`vim.lsp.status()`) while operations are running, then falls back to showing active client names. Uses the native `LspProgress` autocmd — no plugin required.

### Snacks Indent Guides

Vertical indent guides (`│`) with scope highlighting for the current block. Animation disabled for performance.

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

### Git

| Key | Action |
|-----|--------|
| `<leader>gl` | Lazygit |
| `<leader>gf` | Lazygit file log |

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
| `<leader>ts` | Run test suite |
| `<leader>tS` | Stop test run |
| `<leader>to` | Toggle test output |
| `<leader>tx` | Trouble: neotest results |

## Format on Save

Configured via conform.nvim. Formatters by filetype:

| Filetype | Formatter |
|----------|-----------|
| Lua | stylua |
| JavaScript / TypeScript / Vue | prettierd → prettier |
| Java | google-java-format |
| Fish | fish_indent |

## Transparency

The catppuccin theme uses `#000000` as base for Ghostty terminal transparency. Floating windows use `winblend = 20`. `NormalFloat`, `FloatBorder`, `Pmenu` backgrounds are cleared to `NONE` on every colorscheme load.
