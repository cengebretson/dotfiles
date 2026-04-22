local M = {}

M.specs = {
	{ src = "https://github.com/romus204/tree-sitter-manager.nvim" },
}

function M.setup()
	local ok, tree = pcall(require, "tree-sitter-manager")
	if not ok then
		return
	end

	tree.setup({
		ensure_installed = { "java", "typescript", "python", "javascript", "lua", "groovy", "markdown", "markdown_inline", "vue" },
		auto_install = true,
	})

end

return M
