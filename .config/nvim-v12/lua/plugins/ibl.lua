local M = {}

M.specs = {
	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
}

function M.setup()
	local ok, ibl = pcall(require, "ibl")
	if not ok then
		return
	end

	ibl.setup({
		indent = {
			char = "│",
		},
		scope = {
			enabled = false,
		},
	})
end

return M
