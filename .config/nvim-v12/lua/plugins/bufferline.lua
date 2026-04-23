local M = {}

M.specs = {
	{ src = "https://github.com/akinsho/bufferline.nvim" },
}

function M.setup()
	local ok, bufferline = pcall(require, "bufferline")
	if not ok then
		return
	end

	local c = require("core.colors")
	local tab = c.active_tab
	local inactive = c.inactive_tab

	bufferline.setup({
		highlights = {
			background = { bg = inactive },
			buffer_visible = { bg = inactive },
			close_button = { bg = inactive },
			modified = { bg = inactive },
			buffer_selected = { bg = tab, bold = true },
			close_button_selected = { bg = tab },
			modified_selected = { bg = tab },
			numbers_selected = { bg = tab, bold = true },
			indicator_selected = { fg = c.accent, bg = tab },
			diagnostic_selected = { bg = tab },
			error_selected = { bg = tab },
			error_diagnostic_selected = { bg = tab },
			warning_selected = { bg = tab },
			warning_diagnostic_selected = { bg = tab },
			info_selected = { bg = tab },
			info_diagnostic_selected = { bg = tab },
			hint_selected = { bg = tab },
			hint_diagnostic_selected = { bg = tab },
		},
		options = {
			mode = "buffers",
			separator_style = "thin",
			show_buffer_close_icons = true,
			show_close_icon = false,
			color_icons = true,
			always_show_bufferline = false,
			modified_icon = "●",
			indicator = { style = "none" },
			hover = { enabled = true, delay = 150, reveal = { "close" } },
			diagnostics = "nvim_lsp",
			diagnostics_indicator = function(_, _, diag)
				local icons = { error = " ", warning = " ", hint = " " }
				local result = {}
				for name, icon in pairs(icons) do
					if diag[name] and diag[name] > 0 then
						table.insert(result, icon .. diag[name])
					end
				end
				return table.concat(result, " ")
			end,
			offsets = {
				{ filetype = "oil", text = "File Explorer", text_align = "center" },
			},
		},
	})
end

return M
