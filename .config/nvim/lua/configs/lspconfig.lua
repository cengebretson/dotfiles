-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

-- add p8 and pico8 as filetypes to pico8_ls
vim.lsp.config("pico8_ls", {
  filetypes = { "p8", "pico8" },
})

local servers = { "html", "cssls", "pico8_ls", "basedpyright", "ts_ls", "eslint", "ruff" }
vim.lsp.enable(servers)
