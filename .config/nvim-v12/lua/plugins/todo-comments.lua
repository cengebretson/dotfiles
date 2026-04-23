local M = {}

M.specs = {
	{ src = "https://github.com/folke/todo-comments.nvim" },
}

function M.setup()
	local ok, todo = pcall(require, "todo-comments")
	if not ok then
		return
	end

	todo.setup()

	vim.keymap.set("n", "<leader>ft", function() Snacks.picker.todo_comments() end, { desc = "Find TODOs" })
	vim.keymap.set("n", "]t", function() todo.jump_next() end, { desc = "Next TODO" })
	vim.keymap.set("n", "[t", function() todo.jump_prev() end, { desc = "Prev TODO" })
end

return M
