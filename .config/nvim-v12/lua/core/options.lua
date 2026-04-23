vim.o.number = true
vim.o.relativenumber = true
vim.o.timeoutlen = 300

-- Transparent floating windows
vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		if vim.api.nvim_win_get_config(0).relative ~= "" then
			vim.wo.winblend = 20
		end
	end,
})

-- Force float highlight overrides after any colorscheme loads
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		local c = require("core.colors")
		vim.api.nvim_set_hl(0, "LineNr",                  { fg = c.line_nr })
		vim.api.nvim_set_hl(0, "CursorLineNr",            { fg = c.accent, bold = true })
		vim.api.nvim_set_hl(0, "NormalFloat",             { bg = "NONE" })
		vim.api.nvim_set_hl(0, "FloatBorder",             { bg = "NONE" })
		vim.api.nvim_set_hl(0, "FloatTitle",              { bg = "NONE" })
		vim.api.nvim_set_hl(0, "Pmenu",                   { bg = "NONE" })
	end,
})
