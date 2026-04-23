local M = {}

M.specs = {
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
	{ src = "https://github.com/nvim-neotest/neotest" },
	{ src = "https://github.com/nvim-neotest/neotest-python" },
	{ src = "https://github.com/nvim-neotest/neotest-jest" },
}

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
end

return M
