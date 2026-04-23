local M = {}

M.specs = {
	{ src = "https://github.com/stevearc/conform.nvim" },
}

function M.setup()
	local ok, conform = pcall(require, "conform")
	if not ok then return end

	conform.setup({
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			typescript = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			vue = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			python = { "ruff_format" },
			java = { "google-java-format" },
			fish = { "fish_indent" },
		},
		format_on_save = {
			timeout_ms = 500,
			lsp_format = "fallback",
		},
	})

	vim.keymap.set({ "n", "v" }, "<leader>mp", function()
		require("conform").format({
			lsp_fallback = true,
			async = false,
			timeout_ms = 500,
		})
	end, { desc = "Format file or range (manually)" })
end

return M
