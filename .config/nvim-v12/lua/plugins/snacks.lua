local M = {}

M.specs = {
	{ src = "https://github.com/folke/snacks.nvim" },
}

function M.setup()
	local ok, snacks = pcall(require, "snacks")
	if not ok then
		return
	end

	snacks.setup({
		picker = { enabled = true },
		notifier = { enabled = true },
		bigfile = { enabled = true },
		lazygit = { enabled = true },
		terminal = { enabled = true },
		words = { enabled = true },
		dashboard = {
			enabled = true,
			preset = {
				header = [[
  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
				keys = {
					{ icon = "󰈞 ", key = "f", desc = "Find File",    action = ":lua Snacks.picker.files()" },
					{ icon = "󰊄 ", key = "g", desc = "Live Grep",    action = ":lua Snacks.picker.grep()" },
					{ icon = "󱋡 ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
					{ icon = " ", key = "l", desc = "Lazygit",      action = ":lua Snacks.lazygit()" },
					{ icon = "󰒲 ", key = "s", desc = "Sync Plugins", action = ":Pack sync" },
					{ icon = " ", key = "c", desc = "Config",       action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
					{ icon = "󰿅 ", key = "q", desc = "Quit",         action = ":qa" },
				},
			},
			sections = {
				{ section = "header" },
				{ text = os.date("  %A, %B %d  %H:%M"), hl = "SnacksDashboardFooter", align = "center", padding = 1 },
				{ section = "keys", gap = 0, padding = 1 },
			},
		},
		scope = { enabled = false },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		explorer = { enabled = false },
	})

	-- Picker
	vim.keymap.set("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find Files" })
	vim.keymap.set("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Live Grep" })
	vim.keymap.set("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
	vim.keymap.set("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent Files" })
	vim.keymap.set("n", "<leader>fs", function() Snacks.picker.lsp_symbols() end, { desc = "LSP Symbols" })
	vim.keymap.set("n", "<leader>fd", function() Snacks.picker.diagnostics() end, { desc = "Diagnostics" })
	vim.keymap.set("n", "<leader>fk", function() Snacks.picker.keymaps() end, { desc = "Keymaps" })

	-- Git
	vim.keymap.set("n", "<leader>gl", function() Snacks.lazygit() end, { desc = "Lazygit" })
	vim.keymap.set("n", "<leader>gf", function() Snacks.lazygit.log_file() end, { desc = "Lazygit File Log" })

	-- Dashboard
	vim.keymap.set("n", "<leader>fD", function() Snacks.dashboard() end, { desc = "Dashboard" })

	-- Terminal
	vim.keymap.set({ "n", "t" }, "<C-/>", function() Snacks.terminal() end, { desc = "Toggle Terminal" })
end

return M
