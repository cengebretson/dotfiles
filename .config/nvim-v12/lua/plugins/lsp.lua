local M = {}

M.specs = {
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
}

function M.setup()
	vim.diagnostic.config({
		float = { border = "rounded" },
	})

	local function find_python_path(bufnr, root)
		root = root or vim.fs.root(bufnr, { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" })
		if not root then
			return nil
		end

		-- Check local venv directories first
		for _, name in ipairs({ ".venv", "venv", "env", ".env" }) do
			local python = root .. "/" .. name .. "/bin/python"
			if vim.fn.executable(python) == 1 then
				return python
			end
		end

		-- Fall back to uv's managed venv for this project
		if vim.fn.executable("uv") == 1 then
			local uv_python = vim.fn.trim(vim.fn.system("uv run --project " .. vim.fn.shellescape(root) .. " which python 2>/dev/null"))
			if uv_python ~= "" and vim.fn.executable(uv_python) == 1 then
				return uv_python
			end
		end
	end

	vim.lsp.config("basedpyright", {
		settings = {
			basedpyright = {
				analysis = {
					autoSearchPaths = true,
					diagnosticMode = "openFilesOnly",
				},
			},
		},
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client or client.name ~= "basedpyright" then
				return
			end

			local python = find_python_path(ev.buf, client.root_dir)
			if not python then
				return
			end

			local python_settings = { pythonPath = python }
			if client.settings then
				client.settings.python = vim.tbl_deep_extend("force", client.settings.python or {}, python_settings)
			else
				client.config.settings =
					vim.tbl_deep_extend("force", client.config.settings or {}, { python = python_settings })
			end
			client:notify("workspace/didChangeConfiguration", { settings = nil })
		end,
	})

	vim.lsp.config("lua_ls", {
		settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
			},
		},
	})

	require("mason").setup({
		ui = {
			border = "rounded",
			width = 0.8,
			height = 0.8,
		},
	})

	require("mason-lspconfig").setup({
		ensure_installed = { "lua_ls", "basedpyright", "ruff", "ts_ls", "vue_ls", "biome", "cssls", "gopls", "bashls" },
		automatic_enable = true,
	})

	require("mason-tool-installer").setup({
		ensure_installed = {
			"stylua",
			"shellcheck",
			"shfmt",
			"ruff",
			"biome",
			"prettierd",
			"goimports",
			"gofumpt",
			"debugpy",
			"js-debug-adapter",
		},
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "MasonToolsStartingInstall",
		callback = function()
			vim.schedule(function()
				print("Mason: Checking for tools...")
			end)
		end,
	})
end

return M
