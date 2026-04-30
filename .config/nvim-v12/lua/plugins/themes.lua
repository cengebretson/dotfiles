local M = {}

M.specs = {
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
}

function M.setup()
	require("catppuccin").setup({
		flavour = "mocha", -- mocha is the best for dark mode/transparency
		transparent_background = not vim.g.neovide,
		integrations = {
			oil = true,
			blink_cmp = true,
			snacks = true,
			which_key = true,
			gitsigns = true,
			treesitter = true,
		},
		color_overrides = vim.g.neovide and {} or {
			mocha = {
				base = "#000000",
			},
		},
	})

	-- Set the colorscheme
	vim.cmd.colorscheme("catppuccin")

	if vim.g.neovide then
		vim.g.neovide_opacity = 0.92
		vim.g.neovide_normal_opacity = 0.92

		vim.g.neovide_padding_top = 10
		vim.g.neovide_padding_bottom = 7

		vim.o.linespace = 15
		vim.g.neovide_cursor_trail_size = 0.3
		vim.g.neovide_hide_mouse_when_typing = true
		vim.g.neovide_input_macos_option_key_is_meta = "both"

		-- Match floating window transparency to main window
		vim.o.pumblend = 10
		vim.api.nvim_create_autocmd("WinNew", {
			callback = function(ev)
				local cfg = vim.api.nvim_win_get_config(0)
				if cfg.relative ~= "" then
					vim.wo.winblend = 10
				end
			end,
		})
	end
end

return M
