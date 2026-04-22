local M = {}

M.specs = {
	{ src = "https://github.com/windwp/nvim-autopairs" },
}

function M.setup()
	local ok, autopairs = pcall(require, "nvim-autopairs")
	if not ok then
		return
	end

	autopairs.setup({
		check_ts = true,
	})
end

return M
