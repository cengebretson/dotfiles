local M = {}

M.specs = {
	{ src = "https://github.com/folke/flash.nvim" },
}

function M.setup()
	local ok, flash = pcall(require, "flash")
	if not ok then
		return
	end

	flash.setup()

	vim.keymap.set({ "n", "x", "o" }, "s", function() flash.jump() end, { desc = "Flash Jump" })
	vim.keymap.set({ "n", "x", "o" }, "S", function() flash.treesitter() end, { desc = "Flash Treesitter" })
	vim.keymap.set("o", "r", function() flash.remote() end, { desc = "Flash Remote" })
	vim.keymap.set({ "o", "x" }, "R", function() flash.treesitter_search() end, { desc = "Flash Treesitter Search" })
end

return M
