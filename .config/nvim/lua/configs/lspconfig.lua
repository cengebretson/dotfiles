-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

-- add p8 and pico8 as filetypes to pico8_ls
vim.lsp.config("pico8_ls", {
  filetypes = { "p8", "pico8" },
})

-- allow biome to perform diagnostics
vim.lsp.config("ts_ls", {
  settings = {
    format = { enable = false },
    diagnostics = { ignoredCodes = { 6133 } },
  },
})

-- enable servers
local servers = { "html", "lemminx", "cssls", "pico8_ls", "basedpyright", "ts_ls", "biome", "ruff" }
vim.lsp.enable(servers)
