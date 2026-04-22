local M = {}

M.specs = {
	{ src = "https://github.com/folke/which-key.nvim" },
}

function M.setup()
	local ok, wk = pcall(require, "which-key")
	if not ok then
		return
	end

	wk.setup({
		preset = "helix",
		win = {
			border = "rounded",
		},
	})

	-- Register groups to make the menu readable
	wk.add({
		{ "<leader>p", group = "Packages (0.12)" },
		{ "<leader>ps", "<cmd>Pack sync<cr>", desc = "Sync Plugins" },
		{ "<leader>pr", "<cmd>Pack clean<cr>", desc = "Clean/Remove" },
		{ "<leader>pt", "<cmd>Pack status<cr>", desc = "Pack Status" },
		{ "<leader>b", group = "Buffers" },
		{ "<leader>f", group = "Find" },
		{ "<leader>g", group = "Git" },
		{ "<leader>m", group = "Modification/Format" },
		{ "<leader>s", group = "Splits/Windows" },
	})
end

return M
