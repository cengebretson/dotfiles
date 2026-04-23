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
			["<CR>"] = { "select_and_accept", "fallback" },
		},

		appearance = {
			nerd_font_variant = "mono",
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		completion = {
			menu = { border = "rounded" },
			ghost_text = { enabled = true },
		},
	})
end

return M
