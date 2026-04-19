-- Define plugins
local plugins = {
	{ src = "https://github.com/romus204/tree-sitter-manager.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/folke/which-key.nvim" },

	-- autocomplete
	{ src = "https://github.com/Saghen/blink.cmp", tag = "v1.*", build = "cargo build --release" },

	-- lsp plugins
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/williamboman/mason.nvim" },
	{ src = "https://github.com/williamboman/mason-lspconfig.nvim" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },

	-- themes
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
}

vim.pack.add(plugins)

local plugin_configs = {
	"lsp",
	"blink",
	"tree-sitter-manager",
	"oil",
	"conform",
	"which-key",
	"themes",
}

for _, name in ipairs(plugin_configs) do
	local status_ok, module = pcall(require, "plugins." .. name)
	if status_ok then
		module.setup()
	else
		vim.notify("Failed to load plugin config: " .. name, vim.log.levels.ERROR)
	end
end

-- Add "clean" to your :Pack command logic
vim.api.nvim_create_user_command("Pack", function(opts)
	local action = opts.fargs[1]
	if action == "sync" or action == "update" then
		vim.pack.update()
	elseif action == "clean" or action == "remove" then
		-- This triggers the native 0.12 cleanup tool
		vim.pack.clean()
	elseif action == "status" then
		print("Install Path: " .. vim.fn.stdpath("data") .. "/pack/nvim-v12")
	else
		print("Usage: :Pack sync | :Pack clean | :Pack status")
	end
end, {
	nargs = 1,
	complete = function()
		return { "sync", "clean", "status" }
	end,
})
