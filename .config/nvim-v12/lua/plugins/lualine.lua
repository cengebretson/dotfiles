local M = {}

M.specs = {
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
}

function M.setup()
	local ok, lualine = pcall(require, "lualine")
	if not ok then
		return
	end

	local colors = require("catppuccin.palettes").get_palette("mocha")
	local auto = require("lualine.themes.auto")
	local bg = "NONE"

	vim.api.nvim_set_hl(0, "StatusLine", { bg = bg })

	for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "inactive", "terminal" }) do
		if auto[mode] then
			for _, section in ipairs({ "a", "b", "c", "x", "y", "z" }) do
				if auto[mode][section] then
					auto[mode][section].bg = bg
				end
			end
		end
	end

	local function separator()
		return {
			function()
				return "󰇝"
			end,
			color = { fg = colors.overlay2, bg = bg },
			padding = { left = 0, right = 0 },
		}
	end

	local function custom_branch()
		local branch = vim.b.gitsigns_head
		if not branch or branch == "" then
			return ""
		end
		return " " .. branch
	end

	local mode_icons = {
		["NORMAL"] = " ",
		["INSERT"] = " ",
		["VISUAL"] = " ",
		["REPLACE"] = "󰬳 ",
		["COMMAND"] = " ",
		["INACTIVE"] = "󰒲 ",
		["TERMINAL"] = " ",
		["V-BLOCK"] = " ",
		["V-LINE"] = "󰒉 ",
	}

	vim.api.nvim_create_autocmd("User", {
		pattern = "LspProgressStatusUpdated",
		callback = lualine.refresh,
	})

	lualine.setup({
		options = {
			theme = auto,
			component_separators = "",
			section_separators = "",
			globalstatus = true,
		},
		sections = {
			lualine_a = {
				{
					"mode",
					color = { fg = colors.flamingo, bg = bg, gui = "bold" },
					fmt = function(str)
						local reg = vim.fn.reg_recording()
						local prefix = reg ~= "" and (" " .. reg .. "  ") or ""
						return prefix .. (mode_icons[str] or str)
					end,
					padding = { left = 1, right = 1 },
				},
				separator(),
			},
			lualine_b = {
				{
					custom_branch,
					color = { fg = colors.green, bg = bg },
					padding = { left = 1, right = 1 },
				},
				{
					"diff",
					colored = true,
					diff_color = {
						added = { fg = colors.teal, bg = bg, gui = "bold" },
						modified = { fg = colors.yellow, bg = bg, gui = "bold" },
						removed = { fg = colors.red, bg = bg, gui = "bold" },
					},
					padding = { left = 0, right = 1 },
				},
				separator(),
			},
			lualine_c = {
				{
					"filetype",
					icon_only = true,
					colored = true,
					color = { bg = bg },
					padding = { left = 1, right = 0 },
				},
				{
					"filename",
					file_status = true,
					path = 0,
					shorting_target = 20,
					symbols = {
						modified = "[+]",
						readonly = "[-]",
						unnamed = "[?]",
						newfile = "[!]",
					},
					color = { fg = colors.blue, bg = bg },
					padding = { left = 0, right = 1 },
				},
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					sections = { "error", "warn", "info", "hint" },
					diagnostics_color = {
						error = { fg = colors.red, bg = bg, gui = "bold" },
						warn = { fg = colors.yellow, bg = bg, gui = "bold" },
						info = { fg = colors.blue, bg = bg, gui = "bold" },
						hint = { fg = colors.teal, bg = bg, gui = "bold" },
					},
					symbols = {
						error = "󰅚 ",
						warn = "󰀪 ",
						info = "󰋽 ",
						hint = "󰌶 ",
					},
					colored = true,
					update_in_insert = false,
					always_visible = false,
					padding = { left = 0, right = 1 },
				},
			},
			lualine_x = {},
			lualine_y = {
				{
					function()
						return require("lsp-progress").progress()
					end,
					color = { fg = colors.yellow, bg = "none" },
					padding = { left = 1, right = 1 },
					icon = { " ", align = "right" },
				},
			},
			lualine_z = {
				separator(),
				{
					function()
						return " " .. vim.fn.line(".") .. ":" .. vim.fn.col(".")
					end,
					color = { fg = colors.red, bg = bg },
					padding = { left = 1, right = 1 },
				},
			},
		},
	})
end

return M
