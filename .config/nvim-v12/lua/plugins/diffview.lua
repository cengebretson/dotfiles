local M = {}

M.specs = {
	{ src = "https://github.com/sindrets/diffview.nvim" },
}

function M.setup()
	local ok, diffview = pcall(require, "diffview")
	if not ok then
		return
	end

	diffview.setup()

	vim.keymap.set("n", "<leader>vD", "<cmd>DiffviewOpen<cr>", { desc = "Diff View" })
	vim.keymap.set("n", "<leader>vh", "<cmd>DiffviewFileHistory %<cr>", { desc = "File History" })
	vim.keymap.set("n", "<leader>vH", "<cmd>DiffviewFileHistory<cr>", { desc = "Repo History" })
	vim.keymap.set("n", "<leader>vx", "<cmd>DiffviewClose<cr>", { desc = "Close Diff" })
end

return M
