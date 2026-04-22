local M = {}

M.specs = {
	{ src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
}

function M.setup()
	local ok, rm = pcall(require, "render-markdown")
	if not ok then
		return
	end

	rm.setup({
		file_types = { "markdown" },
		render_modes = { "n", "c" },
		heading = {
			sign = false,
			icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
		},
		code = {
			sign = false,
			width = "block",
			right_pad = 1,
		},
		checkbox = {
			unchecked = { icon = "󰄱 " },
			checked = { icon = "󰱒 " },
		},
	})
end

return M
