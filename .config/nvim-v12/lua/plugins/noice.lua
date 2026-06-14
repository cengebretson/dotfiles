local M = {}

M.specs = {
	{ src = "https://github.com/MunifTanjim/nui.nvim" },
	{ src = "https://github.com/folke/noice.nvim" },
}

function M.setup()
	local ok, noice = pcall(require, "noice")
	if not ok then
		return
	end

	noice.setup({
		cmdline = { enabled = true },
		messages = { enabled = true },
		notify = { enabled = false },   -- snacks handles this
		popupmenu = { enabled = false }, -- blink handles this
		lsp = {
			progress = { enabled = false },
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
		},
		presets = {
			command_palette = true,
			long_message_to_split = true,
			lsp_doc_border = true,
		},
	})
end

return M
