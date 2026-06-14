local M = {}

M.specs = {
	-- vim.pack uses `version` (not `tag`); `tag` was silently ignored, which left
	-- blink tracking the dev `main` branch and pulling in an unsatisfied
	-- `blink.lib` dependency. Pin to the latest v1.x release instead.
	{ src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.*") },
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

		signature = {
			enabled = true,
			window = { border = "rounded" },
		},
	})
end

return M
