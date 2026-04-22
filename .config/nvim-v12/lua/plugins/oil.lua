local M = {}

M.specs = {
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
}

function M.setup()
	local ok, oil = pcall(require, "oil")
	if not ok then
		return
	end

	oil.setup({
		-- Makes Oil the default explorer (replaces netrw)
		default_file_explorer = true,

		-- Style the columns for your Nerd Fonts in Ghostty
		columns = {
			"icon",
			"permissions",
			"size",
		},

		-- Configuration for the floating window
		float = {
			padding = 2,
			max_width = 90,
			max_height = 25,
			border = "rounded",
		},

		-- File display settings
		view_options = {
			show_hidden = true,
			-- Logic to hide compiled Java classes or heavy directories
			is_always_hidden = function(name)
				return name == ".." or name == ".git" or name:match("%.class$")
			end,
		},

		-- Keymaps INSIDE the Oil buffer
		keymaps = {
			["g?"] = "actions.show_help",
			["<CR>"] = "actions.select",
			["<C-v>"] = "actions.select_vsplit",
			["<C-h>"] = "actions.select_split",
			["<C-p>"] = "actions.preview",
			["<C-c>"] = "actions.close",
			["-"] = "actions.parent", -- Go up a directory
			["_"] = "actions.open_cwd",
			["gs"] = "actions.change_sort",
			["gx"] = "actions.open_external",
			["g."] = "actions.toggle_hidden",
		},
	})

	-- Define the global toggle (using the space-p-o pattern if you like)
	-- This works alongside your Which-Key mappings
	vim.keymap.set("n", "-", function()
		oil.toggle_float()
	end, { desc = "Open Oil (Float)" })
end

return M
