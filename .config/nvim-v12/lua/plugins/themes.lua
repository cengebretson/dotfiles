local M = {}

M.specs = {
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
}

function M.setup()
	require("catppuccin").setup({
		flavour = "mocha", -- mocha is the best for dark mode/transparency
		transparent_background = true,
		integrations = {
			oil = true,
			blink_cmp = true,
			snacks = true,
			which_key = true,
			gitsigns = true,
			treesitter = true,
			bufferline = true,
		},
		color_overrides = {
			mocha = {
				base = "#000000",
			},
		},
	})

	-- Set the colorscheme
	vim.cmd.colorscheme("catppuccin")
end

return M
