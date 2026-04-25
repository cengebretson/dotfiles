local M = {}

M.specs = {
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
}

function M.setup()
	local ok, gitsigns = pcall(require, "gitsigns")
	if not ok then
		return
	end

	gitsigns.setup({
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},
		on_attach = function(bufnr)
			local map = function(mode, l, r, desc)
				vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
			end

			map("n", "]h", gitsigns.next_hunk, "Next hunk")
			map("n", "[h", gitsigns.prev_hunk, "Prev hunk")
			map("n", "<leader>gp", gitsigns.preview_hunk, "Preview hunk")
			map("n", "<leader>gs", gitsigns.stage_hunk, "Stage hunk")
			map("n", "<leader>gr", gitsigns.reset_hunk, "Reset hunk")
			map("n", "<leader>gb", function() gitsigns.blame_line({ full = true }) end, "Blame line")
			map("n", "<leader>gB", gitsigns.toggle_current_line_blame, "Toggle blame virtualtext")
			map("n", "<leader>gd", gitsigns.diffthis, "Diff this")
		end,
	})
end

return M
