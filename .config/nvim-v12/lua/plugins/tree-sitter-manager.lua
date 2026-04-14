local M = {}

function M.setup()
	local ok, tree = pcall(require, "tree-sitter-manager")
	if not ok then
		return
	end

	tree.setup({
		ensure_installed = { "java", "typescript", "python", "javascript", "lua", "groovy", "markdown" },
		auto_install = true,
	})
end

return M
