-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "nord",
  transparency = true,
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

M.lsp = {
  signature = false,
}

M.nvdash = {
  header = require("configs.headers").get_header(0, true),
  load_on_startup = true,
}

M.ui = {
  cmp = {
    style = "atom",
  },
  telescope = {
    style = "bordered",
  },
  tabufline = {
    order = { "treeOffset", "buffers", "tabs" },
    lazyload = false,
  },
  statusline = {
    enabled = false, -- using lualine instead
  },
}

return M
