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

local function pack_declared_names()
	local set = {}
	for _, spec in ipairs(all_specs) do
		local name = spec.name or spec.src:gsub("%.git$", ""):match("([^/]+)$")
		if name then
			set[name] = true
		end
	end
	return set
end

local pack_install_path = vim.fn.stdpath("data") .. "/site/pack/core/opt"

vim.api.nvim_create_user_command("Pack", function(opts)
	local action = opts.fargs[1]
	if action == "sync" or action == "update" then
		vim.pack.update()
	elseif action == "status" then
		local installed = vim.pack.get()
		table.sort(installed, function(a, b)
			return a.spec.name < b.spec.name
		end)
		local declared = pack_declared_names()
		local lines = { ("Installed plugins (%d):"):format(#installed) }
		for _, p in ipairs(installed) do
			local tag = declared[p.spec.name] and "" or "  (orphan)"
			table.insert(lines, ("  %-28s %s%s"):format(p.spec.name, (p.rev or ""):sub(1, 7), tag))
		end
		table.insert(lines, "Install path: " .. pack_install_path)
		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
	elseif action == "clean" or action == "remove" then
		local declared = pack_declared_names()
		local orphans = {}
		for _, p in ipairs(vim.pack.get()) do
			if not declared[p.spec.name] then
				table.insert(orphans, p.spec.name)
			end
		end
		if #orphans == 0 then
			vim.notify("Pack: no orphaned plugins to remove", vim.log.levels.INFO)
			return
		end
		local prompt = ("Remove %d orphaned plugin(s)?\n%s"):format(#orphans, table.concat(orphans, ", "))
		if vim.fn.confirm(prompt, "&Yes\n&No", 2) == 1 then
			vim.pack.del(orphans)
			vim.notify("Pack: removed " .. table.concat(orphans, ", "), vim.log.levels.INFO)
		end
	else
		print("Usage: :Pack sync | :Pack clean | :Pack status")
	end
end, {
	nargs = 1,
	bar = true, -- allow ':Pack sync | MasonToolsInstall' to chain (e.g. dashboard sync)
	complete = function()
		return { "sync", "clean", "status" }
	end,
})
