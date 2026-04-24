local M = {}

M.specs = {
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/williamboman/mason.nvim" },
	{ src = "https://github.com/williamboman/mason-lspconfig.nvim" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
}

function M.setup()
	vim.diagnostic.config({
		float = { border = "rounded" },
	})

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

	vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
		return vim.lsp.handlers.signature_help(err, result, ctx, vim.tbl_extend("force", config or {}, {
			border = "rounded",
			max_width = 80,
		}))
	end

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
