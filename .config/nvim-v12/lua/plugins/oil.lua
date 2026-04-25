local M = {}

M.specs = {
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
}

local function parse_output(proc)
	local result = proc:wait()
	local ret = {}
	if result.code == 0 then
		for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
			line = line:gsub("/$", "")
			ret[line] = true
		end
	end
	return ret
end

local function new_git_status()
	return setmetatable({}, {
		__index = function(self, key)
			local ignore_proc = vim.system(
				{ "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
				{ cwd = key, text = true }
			)
			local tracked_proc = vim.system({ "git", "ls-tree", "HEAD", "--name-only" }, { cwd = key, text = true })
			local ret = {
				ignored = parse_output(ignore_proc),
				tracked = parse_output(tracked_proc),
			}
			rawset(self, key, ret)
			return ret
		end,
	})
end

function M.setup()
	local ok, oil = pcall(require, "oil")
	if not ok then
		return
	end

	local git_status = new_git_status()
	local refresh = require("oil.actions").refresh
	local orig_refresh = refresh.callback
	refresh.callback = function(...)
		git_status = new_git_status()
		orig_refresh(...)
	end

	local detail = false

	function _G.get_oil_winbar()
		local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
		local dir = oil.get_current_dir(bufnr)
		if dir then
			return vim.fn.fnamemodify(dir, ":~")
		else
			return vim.api.nvim_buf_get_name(0)
		end
	end

	oil.setup({
		default_file_explorer = true,
		columns = { "icon", "git_status", "permissions", "size" },
		float = {
			padding = 2,
			max_width = 90,
			max_height = 25,
			border = "rounded",
		},
		win_options = {
			winbar = "%!v:lua.get_oil_winbar()",
		},
		view_options = {
			show_hidden = true,
			is_always_hidden = function(name)
				return name == ".." or name:match("%.class$")
			end,
			is_hidden_file = function(name, bufnr)
				local dir = oil.get_current_dir(bufnr)
				local is_dotfile = vim.startswith(name, ".") and name ~= ".."
				if not dir then return is_dotfile end
				if is_dotfile then
					return not git_status[dir].tracked[name]
				else
					return git_status[dir].ignored[name]
				end
			end,
		},
		keymaps = {
			["g?"] = "actions.show_help",
			["<CR>"] = "actions.select",
			["<C-v>"] = "actions.select_vsplit",
			["<C-h>"] = "actions.select_split",
			["<C-p>"] = "actions.preview",
			["<C-c>"] = "actions.close",
			["-"] = "actions.parent",
			["_"] = "actions.open_cwd",
			["gs"] = "actions.change_sort",
			["gx"] = "actions.open_external",
			["g."] = "actions.toggle_hidden",
			["gd"] = {
				desc = "Toggle file detail view",
				callback = function()
					detail = not detail
					if detail then
						oil.set_columns({ "icon", "git_status", "permissions", "size", "mtime" })
					else
						oil.set_columns({ "icon", "git_status" })
					end
				end,
			},
		},
	})

	vim.keymap.set("n", "-", function()
		oil.toggle_float()
	end, { desc = "Open Oil (Float)" })
end

return M
