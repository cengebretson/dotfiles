local M = {}

M.specs = {
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/williamboman/mason.nvim" },
	{ src = "https://github.com/williamboman/mason-lspconfig.nvim" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
}

function M.setup()
	vim.lsp.config("lua_ls", {
		settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
			},
		},
	})

	local float_opts = {
		border = "rounded",
		max_width = 80,
		winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
	}

	vim.lsp.handlers["textDocument/hover"]         = vim.lsp.with(vim.lsp.handlers.hover, float_opts)
	vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, float_opts)

	require("mason").setup()

	require("mason-lspconfig").setup({
		ensure_installed = { "lua_ls", "basedpyright", "ts_ls", "vue_ls" },
		automatic_enable = true,
	})

	require("mason-tool-installer").setup({
		ensure_installed = {
			"stylua",
			"shellcheck",
			"ruff",
			"eslint_d",
		},
	})

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
