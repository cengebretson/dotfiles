local M = {}

function M.setup()
	-- 1. Define custom configs BEFORE enabling them.
	-- This handles your 'vim' global warning for Lua.
	vim.lsp.config("lua_ls", {
		settings = {
			Lua = {
				diagnostics = {
					globals = { "vim" },
				},
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
			},
		},
	})

	-- Setup Mason (The binary installer)
	require("mason").setup()

	-- Setup Mason-LSPConfig (The bridge)
	require("mason-lspconfig").setup({
		ensure_installed = { "lua_ls" },
		-- In 0.12, this plugin can handle the enabling for you!
		automatic_enable = true,
	})

	-- Setup Tool Installer (For your formatting/linting)
	require("mason-tool-installer").setup({
		ensure_installed = {
			"stylua",
			"shellcheck",
		},
	})

	-- Wait until Neovim is finished starting up to run the install.
	-- This prevents the "Not an editor command" error.
	vim.api.nvim_create_autocmd("User", {
		pattern = "MasonToolsStartingInstall",
		callback = function()
			vim.schedule(function()
				print("Mason: Checking for tools...")
			end)
		end,
	})
end

return M
