# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Neovim 0.12 configuration built specifically around the **native `vim.pack` plugin manager** — no lazy.nvim or packer. The name "nvim-v12" reflects this tight coupling to Neovim 0.12's new APIs.

## Plugin Management

See the Plugin Management section in `README.md` (the canonical copy) for `vim.pack` declarations, the `:Pack` command, and the `blink.cmp` Rust build requirement.

## Architecture

```
init.lua                  # enables vim.loader, requires core.* and plugins
lua/
  core/
    ai.lua                # Claude Code tmux integration keymaps
    colors.lua            # colorscheme/highlight setup
    keymaps.lua           # global keymaps, leader = <Space>
    options.lua           # vim options + the custom statuscolumn implementation
    tabline.lua           # custom tabline
    treesitter-select.lua # native treesitter incremental selection
  plugins/
    init.lua              # plugin declarations + Pack command + loader loop
    <name>.lua            # one file per plugin (~20: blink, lsp, conform, oil, dap,
                          #   neotest, trouble, gitsigns, diffview, snacks, themes, …)
```

There is no `after/ftplugin/` directory yet — create `after/ftplugin/<ft>.lua` for filetype overrides.

Each `lua/plugins/*.lua` file exports a table with a `setup()` function. The loader in `lua/plugins/init.lua` calls each with `pcall` error isolation.

## Key Conventions

- **Neovim 0.12 APIs**: Use `vim.lsp.config()` (not `lspconfig`), `vim.pack.*`, and `automatic_enable = true` in mason-lspconfig. Avoid patterns from older configs.
- **Plugin config pattern**: Each plugin gets its own file in `lua/plugins/`, returning `{ setup = function() ... end }`. Register it in the `plugin_modules` list inside `lua/plugins/init.lua`.
- **Filetype overrides**: Create `after/ftplugin/<ft>.lua` (directory doesn't exist yet).
- **Transparency**: The catppuccin theme uses a pure black base (`#000000`) for Ghostty terminal transparency. Floating windows use `winblend = 10`. Preserve this when adding new windows.
- **Format tools** (conform.nvim): `stylua` (Lua), `biome`→`prettierd`→`prettier` (JS/TS/Vue), `goimports`→`gofumpt` (Go), `ruff` (Python), `google-java-format` (Java), `fish_indent` (Fish) — all Mason-managed except `fish_indent`.
- **Treesitter — native, no `nvim-treesitter`**: Grammars are installed by `tree-sitter-manager` (`lua/plugins/tree-sitter-manager.lua`, `ensure_installed`); highlighting, injections, folding (`vim.treesitter.foldexpr()` set in `core/options.lua`), and incremental selection (`core/treesitter-select.lua`) all use native `vim.treesitter` directly. This is deliberate: Neovim core keeps absorbing treesitter, and native features light up from grammars + queries alone, so the config gains them for free as core evolves (folding was a 2-line toggle once the queries were present). **Don't reflexively add `nvim-treesitter`** — check what native already covers first. Known gaps: no native TS indentation (mitigated by conform format-on-save) and no textobjects (intentionally skipped). Add new languages to `ensure_installed`.

