-- Set leader key to space (standard for modern Neovim)
vim.g.mapleader = " "

-- Fast saving
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader><leader>", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })

-- Easier command mode
vim.keymap.set("n", ";", ":", { desc = "Command mode" })

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
vim.keymap.set("n", "<leader>q", "<C-w>c", { desc = "Close Window" })

-- Window splitting (Intuitive)
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split Vertical" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split Horizontal" })

-- Keep cursor centered when scrolling and searching
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Navigate splits
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top split" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Join line without moving cursor
vim.keymap.set("n", "J", "mzJ`z")

-- Paste/delete without overwriting clipboard
vim.keymap.set("v", "p", [["_dP]], { desc = "Paste (keep clipboard)" })
vim.keymap.set("v", "<leader>p", [["+p]], { desc = "Paste from clipboard" })
vim.keymap.set({ "n", "v" }, "d", [["_d]], { desc = "Delete to black hole" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["+d]], { desc = "Delete to clipboard" })

-- LSP
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
vim.keymap.set("n", "K", function()
	vim.lsp.buf.hover({ border = "rounded", focusable = true })
end, { desc = "Hover docs" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Type definition" })

-- Diagnostics
vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- Insert mode shortcuts
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>", { desc = "Save from insert mode" })

-- Split resizing
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>")
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>")
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>")
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>")

-- Toggle spell check
vim.keymap.set("n", "<leader>ts", function()
	vim.wo.spell = not vim.wo.spell
	vim.notify("Spell check " .. (vim.wo.spell and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle spell check" })

-- Blank lines without insert mode
vim.keymap.set("n", "<leader>o", "o<Esc>", { desc = "Add line below" })
vim.keymap.set("n", "<leader>O", "O<Esc>", { desc = "Add line above" })

-- Move lines in normal and visual mode
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Quickfix navigation
local function wrap_cnext()
	if not pcall(vim.cmd.cnext) then
		pcall(vim.cmd.cfirst)
	end
end
local function wrap_cprev()
	if not pcall(vim.cmd.cprev) then
		pcall(vim.cmd.clast)
	end
end
vim.keymap.set("n", "]q", wrap_cnext, { desc = "Next quickfix (wrap)" })
vim.keymap.set("n", "[q", wrap_cprev, { desc = "Prev quickfix (wrap)" })
vim.keymap.set("n", "]Q", "<cmd>clast<CR>", { desc = "Last quickfix" })
vim.keymap.set("n", "[Q", "<cmd>cfirst<CR>", { desc = "First quickfix" })
vim.keymap.set("n", "<leader>xq", function()
	local wins = vim.fn.getqflist({ winid = 0 }).winid
	if wins ~= 0 then
		vim.cmd("cclose")
	else
		vim.cmd("copen")
	end
end, { desc = "Toggle quickfix" })

-- Claude Code tmux integration
require("core.claude")

-- Treesitter incremental selection
require("core.treesitter-select")
