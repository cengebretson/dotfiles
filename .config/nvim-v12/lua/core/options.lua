
-- Basic 0.12 Settings
vim.o.number = true
vim.o.relativenumber = true
--vim.cmd.colorscheme("kanagawa")

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
		vim.api.nvim_set_hl(0, "LineNr",       { fg = c.line_nr })
		vim.api.nvim_set_hl(0, "CursorLineNr", { fg = c.accent, bold = true })
		vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "NONE" })
		vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "FloatTitle", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "Pmenu", { bg = "NONE" })

		local c = require("core.colors")
		vim.api.nvim_set_hl(0, "BufferLineBackground",    { bg = c.inactive_tab })
		vim.api.nvim_set_hl(0, "BufferLineFill",          { bg = "NONE" })
		vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = c.inactive_tab })
	end,
})

-- Patch dynamically generated bufferline devicon highlights on each new buffer
local c = require("core.colors")
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		for _, hlname in ipairs(vim.fn.getcompletion("BufferLine*Selected", "highlight")) do
			local hl = vim.api.nvim_get_hl(0, { name = hlname, link = false })
			if hl and not vim.tbl_isempty(hl) and not hl.link then
				hl.bg = c.active_tab_int
				vim.api.nvim_set_hl(0, hlname, hl)
			end
		end
	end,
})
