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
end

return M
