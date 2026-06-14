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

	local config = {
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
	}

	-- Defer noice.setup() until after startup so it isn't attached during the
	-- initial redraw (dashboard/image render), which otherwise flashes a phantom
	-- centered cmdline (command_palette) before the dashboard appears.
	local function deferred_setup()
		vim.schedule(function()
			noice.setup(config)
		end)
	end
	if vim.v.vim_did_enter == 1 then
		deferred_setup()
	else
		vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = deferred_setup })
	end
end

return M
