require "nvchad.autocmds"

-- listen lsp-progress event and refresh lualine
vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = "lualine_augroup",
  pattern = "LspProgressStatusUpdated",
  ---@diagnostic disable-next-line: assign-type-mismatch
  callback = require("lualine").refresh,
})

-- disable status bar for NvDash page
vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function()
    local filetype = vim.bo.filetype
    if filetype == "nvdash" then
      vim.o.laststatus = 0
    else
      vim.o.laststatus = 3
    end
  end,
})
