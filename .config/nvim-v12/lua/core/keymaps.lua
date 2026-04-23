-- Set leader key to space (standard for modern Neovim)
vim.g.mapleader = " "

-- Fast saving
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })

-- Clear search highlights with ESC
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Stay in visual mode when indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Move lines up and down (like Alt+Up/Down in IntelliJ)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Fast buffer switching (Better than tabs for Java development)
vim.keymap.set("n", "<S-h>", ":bprevious<CR>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<S-l>", ":bnext<CR>", { desc = "Next Buffer" })

-- Close current buffer without closing the window
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete Buffer" })

-- Window splitting (Intuitive)
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split Vertical" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split Horizontal" })

-- Sync with system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Treesitter incremental selection using built-in vim.treesitter
local ts_history = {}

local function select_node(node)
	local sr, sc, er, ec = node:range()
	vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
	vim.cmd("normal! v")
	vim.api.nvim_win_set_cursor(0, { er + 1, math.max(0, ec - 1) })
end

vim.keymap.set("n", "<CR>", function()
	local node = vim.treesitter.get_node()
	if not node then return end
	ts_history = { node }
	select_node(node)
end, { desc = "Select treesitter node" })

vim.keymap.set("v", "<CR>", function()
	local last = ts_history[#ts_history]
	if not last then return end
	local parent = last:parent()
	if parent then
		table.insert(ts_history, parent)
		select_node(parent)
	end
end, { desc = "Expand treesitter selection" })

vim.keymap.set("v", "<BS>", function()
	if #ts_history > 1 then
		table.remove(ts_history)
		select_node(ts_history[#ts_history])
	else
		vim.cmd("normal! \27")
	end
end, { desc = "Shrink treesitter selection" })
