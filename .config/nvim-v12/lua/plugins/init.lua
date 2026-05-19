local modules = {
	"blink",
	"lsp",
	"oil",
	"conform",
	"which-key",
	"themes",
	"tree-sitter-manager",
	"gitsigns",
	"snacks",
	"render-markdown",
	"autopairs",
	"surround",
	"trouble",
	"todo-comments",
	"diffview",
	"noice",
	"flash",
	"neotest",
	"dap",
	"lualine",
	-- "ibl", -- replaced by snacks.indent
}
local all_specs = {}
local loaded = {}

for _, name in ipairs(modules) do
	local ok, mod = pcall(require, "plugins." .. name)
	if ok then
		loaded[name] = mod
		vim.list_extend(all_specs, mod.specs or {})
	else
		vim.notify("Failed to load plugin spec: " .. name, vim.log.levels.ERROR)
	end
end

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local spec, kind, path = ev.data.spec, ev.data.kind, ev.data.path
		if spec.name == "blink.cmp" and (kind == "install" or kind == "update") then
			vim.notify("blink.cmp: building fuzzy matcher...", vim.log.levels.INFO)
			vim.system({ "cargo", "build", "--release" }, { cwd = path }, function(result)
				if result.code == 0 then
					vim.schedule(function()
						vim.notify("blink.cmp: build complete", vim.log.levels.INFO)
					end)
				else
					vim.schedule(function()
						vim.notify("blink.cmp: build failed\n" .. (result.stderr or ""), vim.log.levels.ERROR)
					end)
				end
			end)
		end
	end,
})

vim.pack.add(all_specs)

for _, name in ipairs(modules) do
	local mod = loaded[name]
	if mod and mod.setup then
		mod.setup()
	end
end

vim.api.nvim_create_user_command("Pack", function(opts)
	local action = opts.fargs[1]
	if action == "sync" or action == "update" then
		vim.pack.update()
	elseif action == "clean" or action == "remove" then
		vim.notify("vim.pack has no clean command — remove unused plugins manually from: " .. vim.fn.stdpath("data") .. "/pack/nvim-v12/start/", vim.log.levels.WARN)
	elseif action == "status" then
		print("Install Path: " .. vim.fn.stdpath("data") .. "/pack/nvim-v12")
	else
		print("Usage: :Pack sync | :Pack clean | :Pack status")
	end
end, {
	nargs = 1,
	complete = function()
		return { "sync", "clean", "status" }
	end,
})
