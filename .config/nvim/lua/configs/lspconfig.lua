-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "pico8_ls", "basedpyright" }
vim.lsp.enable(servers)
