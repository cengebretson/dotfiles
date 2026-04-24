local M = {}

M.specs = {
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
	{ src = "https://github.com/nvim-neotest/neotest" },
	{ src = "https://github.com/nvim-neotest/neotest-python" },
	{ src = "https://github.com/nvim-neotest/neotest-jest" },
}

local function make_bun_adapter()
	local lib = require("neotest.lib")
	local adapter = { name = "neotest-bun" }

	adapter.root = function(path)
		return lib.files.match_root_pattern("bun.lock", "bun.lockb")(path)
	end

	function adapter.is_test_file(file_path)
		return file_path ~= nil
			and (file_path:match("%.test%.[jt]sx?$") ~= nil or file_path:match("%.spec%.[jt]sx?$") ~= nil)
	end

	function adapter.filter_dir(name)
		return name ~= "node_modules"
	end

	function adapter.discover_positions(path)
		-- Delegate to neotest-jest if available (reuses its treesitter query)
		local ok, jest = pcall(require, "neotest-jest")
		if ok then
			local inst = jest({})
			return inst.discover_positions(path)
		end
		-- Minimal fallback query
		local query = [[
			((call_expression
				function: (identifier) @func_name (#any-of? @func_name "describe" "fdescribe" "xdescribe")
				arguments: (arguments ((_) @namespace.name) [(arrow_function)(function_expression)])
			)) @namespace.definition

			((call_expression
				function: (identifier) @func_name (#any-of? @func_name "test" "it" "fit" "xit")
				arguments: (arguments ((_) @test.name) [(arrow_function)(function_expression)])
			)) @test.definition
		]]
		return lib.treesitter.parse_positions(path, query, { nested_namespaces = true })
	end

	function adapter.build_spec(args)
		local pos = args.tree:data()
		local root = adapter.root(pos.path)
		local cmd = { "bun", "test", pos.path }
		if pos.type == "test" then
			table.insert(cmd, "--test-name-pattern")
			table.insert(cmd, pos.name)
		end
		return { command = cmd, cwd = root }
	end

	function adapter.results(spec, result, tree)
		local results = {}
		local status = result.code == 0 and "passed" or "failed"
		-- Parse bun's text output to get per-test status
		local output = result.output or ""
		for _, node in tree:iter_nodes() do
			local pos = node:data()
			if pos.type == "test" then
				local passed = output:match("%u2714%s+" .. vim.pesc(pos.name)) -- ✔ name
				local failed = output:match("%u2718%s+" .. vim.pesc(pos.name)) -- ✘ name
				results[pos.id] = {
					status = passed and "passed" or (failed and "failed" or status),
				}
			end
		end
		-- Fallback: mark root node
		if vim.tbl_isempty(results) then
			results[spec.tree:data().id] = { status = status, output = result.output }
		end
		return results
	end

	return adapter
end

function M.setup()
	local ok, neotest = pcall(require, "neotest")
	if not ok then
		return
	end

	local adapters = {}

	local ok_py, neotest_python = pcall(require, "neotest-python")
	if ok_py then
		table.insert(adapters, neotest_python({ dap = { justMyCode = false }, runner = "pytest" }))
	end

	local ok_jest, neotest_jest = pcall(require, "neotest-jest")
	if ok_jest then
		table.insert(adapters, neotest_jest({ jestCommand = "npx jest" }))
	end

	table.insert(adapters, make_bun_adapter())

	neotest.setup({ adapters = adapters })

	vim.keymap.set("n", "<leader>tt", function() neotest.run.run() end, { desc = "Run Nearest Test" })
	vim.keymap.set("n", "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "Run File" })
	vim.keymap.set("n", "<leader>ts", function() neotest.run.run({ suite = true }) end, { desc = "Run Suite" })
	vim.keymap.set("n", "<leader>tl", function() neotest.run.run_last() end, { desc = "Run Last" })
	vim.keymap.set("n", "<leader>to", function() neotest.output.open({ enter = true }) end, { desc = "Open Output" })
	vim.keymap.set("n", "<leader>tS", function() neotest.summary.toggle() end, { desc = "Toggle Summary" })
	vim.keymap.set("n", "<leader>tp", function() neotest.output_panel.toggle() end, { desc = "Toggle Output Panel" })
	vim.keymap.set("n", "]n", function() neotest.jump.next({ status = "failed" }) end, { desc = "Next Failed Test" })
	vim.keymap.set("n", "[n", function() neotest.jump.prev({ status = "failed" }) end, { desc = "Prev Failed Test" })
	vim.keymap.set("n", "<leader>tx", function() require("trouble").open({ source = "neotest" }) end, { desc = "Failed Tests (Trouble)" })
end

return M
