local M = {}

M.specs = {
	{ src = "https://github.com/Saghen/blink.cmp", tag = "v1.*", build = "cargo build --release" },
}

function M.setup()
	local ok, blink = pcall(require, "blink.cmp")
	if not ok then
		return
	end

	blink.setup({
		keymap = {
			preset = "super-tab",
			-- Optional: If you still want Enter to confirm the selection
			-- otherwise, you just keep typing or use Tab to cycle.
			["<CR>"] = { "select_and_accept", "fallback" },
		},

		appearance = {
			use_nvim_get_runtime_file = true,
			nerd_font_variant = "mono",
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		-- Use 'menu' for the popup and 'ghost_text' for that
		-- "Copilot-style" preview of the top suggestion
		completion = {
			menu = { border = "rounded" },
			ghost_text = { enabled = true },
		},
	})
end

return M
