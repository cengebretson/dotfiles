vim.o.showtabline = 1

local function get_icon(bufname)
	local ok, devicons = pcall(require, "nvim-web-devicons")
	if not ok then
		return ""
	end
	local ext = vim.fn.fnamemodify(bufname, ":e")
	local fname = vim.fn.fnamemodify(bufname, ":t")
	local icon = devicons.get_icon(fname, ext, { default = true })
	return icon and (icon .. " ") or ""
end

function _G.MyTabLine()
	local s = ""
	local ntabs = vim.fn.tabpagenr("$")
	for i = 1, ntabs do
		local is_current = i == vim.fn.tabpagenr()
		local buflist = vim.fn.tabpagebuflist(i)
		local winnr = vim.fn.tabpagewinnr(i)
		local bufname = vim.fn.bufname(buflist[winnr])
		local name = bufname ~= "" and vim.fn.fnamemodify(bufname, ":t") or "[No Name]"
		local icon = bufname ~= "" and get_icon(bufname) or ""
		local modified = vim.fn.getbufvar(buflist[winnr], "&modified") == 1

		s = s .. (is_current and "%#TabLineSel#" or "%#TabLine#")
		s = s .. "%" .. i .. "T"
		s = s .. "  " .. icon .. name .. (modified and " ●" or "") .. "  "

		if i < ntabs then
			s = s .. "%#TabLineSep#│"
		end
	end
	return s .. "%#TabLineFill#%T"
end

vim.o.tabline = "%!v:lua.MyTabLine()"

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		local c = require("core.colors")
		vim.api.nvim_set_hl(0, "TabLine",     { fg = c.tab_inactive, bg = "NONE" })
		vim.api.nvim_set_hl(0, "TabLineSel",  { fg = c.accent, bg = "NONE", bold = true })
		vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "TabLineSep",  { fg = c.tab_sep, bg = "NONE" })
	end,
})
