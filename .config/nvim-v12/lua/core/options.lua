vim.o.number = true
vim.o.relativenumber = true
vim.o.clipboard = "unnamedplus"
vim.o.timeoutlen = 300

function _G._statuscolumn()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	local lnum = vim.v.lnum
	local relnum = vim.v.relnum
	local virtnum = vim.v.virtnum
	local nu = vim.wo[win].number
	local rnu = vim.wo[win].relativenumber

	if not (nu or rnu) then return "" end

	local left_icon, right_icon = "  ", "  "
	local show_signs = virtnum == 0 and vim.wo[win].signcolumn ~= "no"
	local show_folds = virtnum == 0 and vim.wo[win].foldcolumn ~= "0"
	if show_signs or show_folds then
		local ok, sc = pcall(require, "snacks.statuscolumn")
		if ok then
			local wanted = { mark = show_signs, sign = show_signs, fold = show_folds, git = show_signs }
			local signs = sc.line_signs(win, buf, lnum, wanted)
			if #signs > 0 then
				local by_type = {}
				for _, s in ipairs(signs) do
					by_type[s.type] = by_type[s.type] or s
				end
				local function find(types)
					for _, t in ipairs(types) do if by_type[t] then return by_type[t] end end
				end
				left_icon = sc.icon(find({ "mark", "sign" }))
				right_icon = sc.icon(find({ "fold", "git" }))
			end
		end
	end

	local num_str = ""
	if virtnum == 0 then
		local num
		if rnu and nu and relnum == 0 then num = lnum
		elseif rnu then num = relnum
		else num = lnum end

		if relnum == 0 then
			num_str = "%#CursorLineNr#" .. num .. " "
		else
			num_str = "%=%#LineNr#" .. num .. " "
		end
	end

	return "%@v:lua.require'snacks.statuscolumn'.click_fold@"
		.. left_icon .. num_str .. right_icon
		.. "%T"
end

vim.o.statuscolumn = "%{%v:lua._statuscolumn()%}"

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
	end,
})

-- Transparent floating windows
vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		if vim.api.nvim_win_get_config(0).relative ~= "" then
			vim.wo.winblend = 10
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
