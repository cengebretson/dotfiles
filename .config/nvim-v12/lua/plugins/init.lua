-- Define plugins
local plugins = {
	"https://github.com/romus204/tree-sitter-manager.nvim",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/folke/which-key.nvim",

	-- The Core LSP Configs (Now required by native 0.12 APIs)
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",

	-- themes
	"https://github.com/rebelot/kanagawa.nvim",
}

-- Add them to the native package manager
vim.pack.add(plugins)

local plugin_configs = {
	"lsp",
	"tree-sitter-manager",
	"oil",
	"conform",
	"which-key",
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
