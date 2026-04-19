local M = {}

function M.setup()
	local ok, wk = pcall(require, "which-key")
	if not ok then
		return
	end

	wk.setup({
		preset = "helix",
		win = {
			border = "rounded",
			wo = {
				winblend = 10, -- 0 for full transparency, 10 for "frosted" look
			},
		},
	})

	-- Register groups to make the menu readable
	wk.add({
		{ "<leader>p", group = "Packages (0.12)" },
		{ "<leader>ps", "<cmd>Pack sync<cr>", desc = "Sync Plugins" },
		{ "<leader>pr", "<cmd>Pack clean<cr>", desc = "Clean/Remove" },
		{ "<leader>pt", "<cmd>Pack status<cr>", desc = "Pack Status" },
		{ "<leader>b", group = "Buffers" },
		{ "<leader>m", group = "Modification/Format" },
		{ "<leader>s", group = "Splits/Windows" },
	})
end

return M
