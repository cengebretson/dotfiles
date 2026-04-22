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
    blink.lua             # completion (blink.cmp, super-tab preset)
    conform.lua           # format-on-save (stylua, prettierd, google-java-format, fish_indent)
    lsp.lua               # LSP via Mason + mason-lspconfig (automatic_enable = true)
    oil.lua               # file explorer replacing netrw (floating, - to open)
    themes.lua            # catppuccin-mocha, transparent bg for Ghostty
    tree-sitter-manager.lua  # treesitter grammars
    which-key.lua         # key hint popups + leader group labels
after/ftplugin/           # empty, reserved for filetype overrides
```

Each `lua/plugins/*.lua` file exports a table with a `setup()` function. The loader in `lua/plugins/init.lua` calls each with `pcall` error isolation.

## Key Conventions

- **Neovim 0.12 APIs**: Use `vim.lsp.config()` (not `lspconfig`), `vim.pack.*`, and `automatic_enable = true` in mason-lspconfig. Avoid patterns from older configs.
- **Plugin config pattern**: Each plugin gets its own file in `lua/plugins/`, returning `{ setup = function() ... end }`. Register it in the `plugin_modules` list inside `lua/plugins/init.lua`.
- **Filetype overrides**: Add to `after/ftplugin/<ft>.lua` (currently empty).
- **Transparency**: The catppuccin theme uses a pure black base (`#000000`) for Ghostty terminal transparency. Floating windows use `winblend = 10`. Preserve this when adding new windows.
- **Format tools**: `stylua` (Lua), `prettierd`/`prettier` (JS), `google-java-format` (Java), `fish_indent` (Fish) — all managed via Mason except `fish_indent`.

## External Dependencies

Must be available on `$PATH` or installed via Mason before features work:
- `cargo` — required for `blink.cmp` build step
- `fish_indent` — bundled with Fish shell (no Mason install)
- LSP servers and formatters are installed by Mason automatically on first launch
