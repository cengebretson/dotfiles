local M = {}

M.specs = {
	{ src = "https://github.com/mfussenegger/nvim-dap" },
	{ src = "https://github.com/mfussenegger/nvim-dap-python" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui" },
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
}

function M.setup()
	local ok_dap, dap = pcall(require, "dap")
	if not ok_dap then return end

	local ok_dapui, dapui = pcall(require, "dapui")
	local ok_dappy, dap_python = pcall(require, "dap-python")

	if ok_dappy then
		local mason_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
		dap_python.setup(mason_path)
	end

	-- JavaScript / TypeScript / Bun adapter
	local js_debug = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
	if vim.fn.filereadable(js_debug) == 1 then
		dap.adapters["pwa-node"] = {
			type = "server",
			host = "localhost",
			port = "${port}",
			executable = {
				command = "node",
				args = { js_debug, "${port}" },
			},
		}
		dap.adapters["pwa-chrome"] = {
			type = "server",
			host = "localhost",
			port = "${port}",
			executable = {
				command = "node",
				args = { js_debug, "${port}" },
			},
		}

		local js_configs = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file (Node)",
				program = "${file}",
				cwd = "${workspaceFolder}",
				sourceMaps = true,
			},
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file (tsx)",
				runtimeExecutable = "tsx",
				program = "${file}",
				cwd = "${workspaceFolder}",
				sourceMaps = true,
			},
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file (Bun)",
				runtimeExecutable = "bun",
				runtimeArgs = { "--inspect-brk" },
				program = "${file}",
				cwd = "${workspaceFolder}",
				sourceMaps = true,
				attachSimplePort = 6499,
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach to process",
				processId = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
				sourceMaps = true,
			},
			{
				type = "pwa-chrome",
				request = "launch",
				name = "Launch Chrome",
				url = "http://localhost:3000",
				webRoot = "${workspaceFolder}",
				sourceMaps = true,
			},
		}

		for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
			dap.configurations[ft] = js_configs
		end
	end

	if ok_dapui then
		dapui.setup()

		dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
		dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
		dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
	end

	vim.fn.sign_define("DapBreakpoint",          { text = "", texthl = "DiagnosticError" })
	vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn" })
	vim.fn.sign_define("DapStopped",             { text = "", texthl = "DiagnosticInfo" })

	vim.keymap.set("n", "<F5>",       dap.continue,          { desc = "Debug: Continue" })
	vim.keymap.set("n", "<F9>",       dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
	vim.keymap.set("n", "<F10>",      dap.step_over,         { desc = "Debug: Step Over" })
	vim.keymap.set("n", "<F11>",      dap.step_into,         { desc = "Debug: Step Into" })
	vim.keymap.set("n", "<F12>",      dap.step_out,          { desc = "Debug: Step Out" })
	vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
	vim.keymap.set("n", "<leader>dc", dap.continue,          { desc = "Debug: Continue" })
	vim.keymap.set("n", "<leader>do", dap.step_over,         { desc = "Debug: Step Over" })
	vim.keymap.set("n", "<leader>di", dap.step_into,         { desc = "Debug: Step Into" })
	vim.keymap.set("n", "<leader>dO", dap.step_out,          { desc = "Debug: Step Out" })
	vim.keymap.set("n", "<leader>dq", dap.terminate,         { desc = "Debug: Terminate" })
	vim.keymap.set("n", "<leader>dB", function()
		dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
	end, { desc = "Debug: Conditional Breakpoint" })

	if ok_dapui then
		vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
		vim.keymap.set({ "n", "v" }, "<leader>de", dapui.eval, { desc = "Debug: Eval Expression" })
	end
end

return M
