local M = {}

M.specs = {
	{ src = "https://github.com/stevearc/conform.nvim" },
}

function M.setup()
	local ok, conform = pcall(require, "conform")
	if not ok then
		return
	end

	conform.setup({
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
			typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
			vue = { "biome", "prettierd", "prettier", stop_after_first = true },
			go = { "goimports", "gofumpt" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			python = { "ruff_organize_imports", "ruff_format" },
			java = { "google-java-format" },
			fish = { "fish_indent" },
		},
		format_on_save = {
			timeout_ms = 500,
			lsp_format = "fallback",
		},
	})

	vim.keymap.set({ "n", "v" }, "<leader>=", function()
		require("conform").format({
			lsp_format = "fallback",
			async = false,
			timeout_ms = 500,
		})
	end, { desc = "Format file or range" })

	vim.keymap.set("n", "<leader>rF", function()
		require("conform").format({
			formatters = { "ruff_fix" },
			async = false,
			timeout_ms = 500,
		})
	end, { desc = "Ruff fix file" })
end

return M
