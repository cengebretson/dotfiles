local M = {}

M.specs = {
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
}

function M.setup()
	local ok, lualine = pcall(require, "lualine")
	if not ok then
		return
	end

	lualine.setup({
		options = {
			theme = "catppuccin",
			globalstatus = true,
			section_separators = { left = "", right = "" },
			component_separators = { left = "│", right = "│" },
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", "diff", "diagnostics" },
			lualine_c = { { "filename", path = 1 } },
			lualine_x = { "filetype" },
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
	})
end

return M
