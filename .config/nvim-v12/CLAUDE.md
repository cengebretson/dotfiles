# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Neovim 0.12 configuration built specifically around the **native `vim.pack` plugin manager** — no lazy.nvim or packer. The name "nvim-v12" reflects this tight coupling to Neovim 0.12's new APIs.

## Plugin Management

Plugins are declared in `lua/plugins/init.lua` using `vim.pack.add()` and pinned via `nvim-pack-lock.json` (SHA-based lockfile). Install path: `~/.local/share/nvim/pack/nvim-v12`.

The custom `:Pack` command (also bound to `<leader>p*`) wraps the native API:
- `:Pack sync` — install/update all plugins
- `:Pack clean` — remove unused plugins
- `:Pack status` — show install status

`blink.cmp` has a Rust build step (`cargo build --release`) that runs automatically on install/update — **Rust/cargo must be on PATH**.

## Architecture

```
init.lua                  # enables vim.loader, requires core.* and plugins
lua/
  core/
    options.lua           # vim options (minimal: line numbers)
    keymaps.lua           # global keymaps, leader = <Space>
  plugins/
    init.lua              # plugin declarations + Pack command + loader loop
    <name>.lua            # one file per plugin (~20: blink, lsp, conform, oil, dap,
                          #   neotest, trouble, gitsigns, diffview, snacks, themes, …)
after/ftplugin/           # empty, reserved for filetype overrides
```

Each `lua/plugins/*.lua` file exports a table with a `setup()` function. The loader in `lua/plugins/init.lua` calls each with `pcall` error isolation.

## Key Conventions

- **Neovim 0.12 APIs**: Use `vim.lsp.config()` (not `lspconfig`), `vim.pack.*`, and `automatic_enable = true` in mason-lspconfig. Avoid patterns from older configs.
- **Plugin config pattern**: Each plugin gets its own file in `lua/plugins/`, returning `{ setup = function() ... end }`. Register it in the `plugin_modules` list inside `lua/plugins/init.lua`.
- **Filetype overrides**: Add to `after/ftplugin/<ft>.lua` (currently empty).
- **Transparency**: The catppuccin theme uses a pure black base (`#000000`) for Ghostty terminal transparency. Floating windows use `winblend = 10`. Preserve this when adding new windows.
- **Format tools** (conform.nvim): `stylua` (Lua), `biome`→`prettierd`→`prettier` (JS/TS/Vue), `goimports`→`gofumpt` (Go), `ruff` (Python), `google-java-format` (Java), `fish_indent` (Fish) — all Mason-managed except `fish_indent`.

