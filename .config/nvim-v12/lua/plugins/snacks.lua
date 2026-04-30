local M = {}

M.specs = {
	{ src = "https://github.com/folke/snacks.nvim" },
}

function M.setup()
	local ok, snacks = pcall(require, "snacks")
	if not ok then
		return
	end

	require("snacks.statuscolumn").setup()

	snacks.setup({
		picker = { enabled = true },
		notifier = {
			enabled = true,
			wo = { focusable = false },
		},
		bigfile = { enabled = true },
		lazygit = { enabled = true },
		terminal = { enabled = true },
		words = { enabled = true },
		dashboard = {
			enabled = true,
			preset = {
				keys = {
					{ icon = "󰀼 ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
					{ icon = "󱩾 ", key = "g", desc = "Live Grep", action = ":lua Snacks.picker.grep()" },
					{ icon = "󰋚 ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
					{ icon = "󰊢 ", key = "l", desc = "Lazygit", action = ":lua Snacks.lazygit()" },
					{ icon = "󰚰 ", key = "s", desc = "Sync Plugins", action = ":Pack sync" },
					{
						icon = "󱩷 ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })",
					},
					{ icon = "󱉭 ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
					{ icon = "󰈆 ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
			sections = vim.g.neovide and {
				{ section = "keys", gap = 0, padding = 1 },
			} or {
				{
					section = "image",
					scale = 1.5,
					file = (function()
						local assets = vim.fn.globpath(vim.fn.stdpath("config"), "assets/*", false, true)
						math.randomseed(os.time())
						return assets[math.random(#assets)]
					end)(),
					height = 6,
					padding = 1,
					left_pad = 2,
				},
				{ section = "keys", gap = 0, padding = 1 },
			},
		},
		image = { enabled = true },
		scope = { enabled = true },
		indent = {
			enabled = true,
			indent = { char = "│" },
			scope = { enabled = true, hl = "SnacksIndentScope" },
			animate = { enabled = false },
		},
		scroll = { enabled = true },
		statuscolumn = { enabled = false },
		explorer = { enabled = false },
	})

	-- Register custom image dashboard section using snacks' own image API
	require("snacks.dashboard").sections["image"] = function(opts)
		return function(self)
			local buf = vim.api.nvim_create_buf(false, true)
			local placement
			local win
			return {
				render = function(_, pos)
					local util = require("snacks.image.util")
					local fitted = util.fit(opts.file, { width = vim.o.columns, height = 999 })
					local scale = opts.scale or 1
					local width = math.floor(fitted.width * scale)
					local height = math.floor(fitted.height * scale)
					local win_pos = vim.api.nvim_win_get_position(self.win)
					local abs_row = win_pos[1] + pos[1] - 1
					local center_col = math.floor((vim.o.columns - width) / 2) + (opts.left_pad or 0)
					win = vim.api.nvim_open_win(buf, false, {
						col = center_col,
						row = abs_row,
						focusable = false,
						height = height,
						noautocmd = true,
						relative = "editor",
						zindex = Snacks.config.styles.dashboard.zindex + 1,
						style = "minimal",
						width = width,
						border = "none",
					})
					placement = Snacks.image.buf._attach(buf, { src = opts.file, width = width, height = height })
					if placement then
						vim.schedule(function()
							placement:update()
						end)
					end
					local function close()
						pcall(vim.api.nvim_win_close, win, true)
						pcall(vim.api.nvim_buf_delete, buf, { force = true })
						return true
					end
					self.on("UpdatePre", close, self.augroup)
					self.on("Closed", close, self.augroup)
				end,
				text = ("\n"):rep((opts.height or 10) - 1),
			}
		end
	end

	-- Picker
	vim.keymap.set("n", "<leader>ff", function()
		Snacks.picker.files()
	end, { desc = "Find Files" })
	vim.keymap.set("n", "<leader>fg", function()
		Snacks.picker.grep()
	end, { desc = "Live Grep" })
	vim.keymap.set("n", "<leader>fb", function()
		Snacks.picker.buffers()
	end, { desc = "Buffers" })
	vim.keymap.set("n", "<leader>fr", function()
		Snacks.picker.recent()
	end, { desc = "Recent Files" })
	vim.keymap.set("n", "<leader>fs", function()
		Snacks.picker.lsp_symbols()
	end, { desc = "LSP Symbols" })
	vim.keymap.set("n", "<leader>fd", function()
		Snacks.picker.diagnostics()
	end, { desc = "Diagnostics" })
	vim.keymap.set("n", "<leader>fk", function()
		Snacks.picker.keymaps()
	end, { desc = "Keymaps" })
	vim.keymap.set("n", "<leader>fp", function()
		Snacks.picker.projects()
	end, { desc = "Projects" })

	-- Git
	vim.keymap.set("n", "<leader>gl", function()
		Snacks.lazygit()
	end, { desc = "Lazygit" })
	vim.keymap.set("n", "<leader>gf", function()
		Snacks.lazygit.log_file()
	end, { desc = "Lazygit File Log" })

	-- Dashboard
	vim.keymap.set("n", "<leader>fD", function()
		Snacks.dashboard()
	end, { desc = "Dashboard" })

	-- Terminal
	vim.keymap.set({ "n", "t" }, "<C-/>", function()
		Snacks.terminal()
	end, { desc = "Toggle Terminal" })
end

return M
