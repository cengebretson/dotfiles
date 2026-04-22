local M = {}

M.specs = {
	{ src = "https://github.com/folke/trouble.nvim" },
}

function M.setup()
	local ok, trouble = pcall(require, "trouble")
	if not ok then
		return
	end

	trouble.setup({
		modes = {
			diagnostics = {
				auto_close = true,
			},
		},
	})

	vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Workspace Diagnostics" })
	vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Document Diagnostics" })
	vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols" })
	vim.keymap.set("n", "<leader>xl", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP References" })
	vim.keymap.set("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "TODOs" })
end

return M
