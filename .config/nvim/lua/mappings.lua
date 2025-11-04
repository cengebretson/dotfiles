require "nvchad.mappings"

local map = vim.keymap.set

-- keymappings for Neotest
map("n", "<leader>ta", function()
  require("neotest").run.run { suite = true }
end, { desc = "Run all tests" })
map("n", "<leader>tr", function()
  require("neotest").run.run()
end, { desc = "Run current test" })
map("n", "<leader>tx", function()
  require("neotest").run.stop()
end, { desc = "Stop Neotest" })
map("n", "<leader>to", function()
  require("neotest").output_panel.toggle()
end, { desc = "Open Neotest output" })
map("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Open Neotest summary" })

-- overwriting the same lines in NvChad mapping file, in order to add 'async = true'
map("n", "<leader>fm", function()
  require("conform").format { async = true, lsp_fallback = true }
end, { desc = "custom format files" })

-- trigger tiny code action
map({ "n", "x" }, "<leader>ca", function()
  require("tiny-code-action").code_action {}
end, { noremap = true, silent = true, desc = "tiny code action" })

-- essential keymaps
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })
map("v", "p", '"_dP', { desc = "Better paste" })
map("n", "Y", "y$", { desc = "Yank to end of line" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection up" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection down" })

-- quickfix and loclist maps
map("n", "<leader>qf", vim.diagnostic.setqflist, { desc = "Set QuickFix List" })

-- Wrap around Quickfix navigation
function _G.wrap_cnext()
  local success, _ = pcall(vim.cmd.cnext)
  if not success then
    pcall(vim.cmd.cfirst)
  end
end

function _G.wrap_cprev()
  local success, _ = pcall(vim.cmd.cprev)
  if not success then
    pcall(vim.cmd.clast)
  end
end

-- Navigate quickfix list
map("n", "[q", "<cmd>lua wrap_cprev()<CR>", { desc = "cprev" })
map("n", "]q", "<cmd>lua wrap_cnext()<CR>", { desc = "cnext" })
map("n", "[Q", "<cmd>cfirst<CR>", { desc = "cfirst" })
map("n", "]Q", "<cmd>clast<CR>", { desc = "clast" })

-- Wrap around LocList navigation
function _G.wrap_lnext()
  local success, _ = pcall(vim.cmd.lnext)
  if not success then
    pcall(vim.cmd.lfirst)
  end
end

function _G.wrap_lprev()
  local success, _ = pcall(vim.cmd.lprev)
  if not success then
    pcall(vim.cmd.llast)
  end
end

-- Naiviage loclist
map("n", "[l", "<cmd>lua wrap_lprev()<CR>", { desc = "lprev" })
map("n", "]l", "<cmd>lua wrap_lnext()<CR>", { desc = "lnext" })
map("n", "[L", "<cmd>lfirst<CR>", { desc = "lfirst" })
map("n", "]L", "<cmd>llast<CR>", { desc = "llast" })

-- toggle Transparency
map(
  "n",
  "<leader>tt",
  ":lua require('base46').toggle_transparency()<CR>",
  { noremap = true, silent = true, desc = "Toggle Background Transparency" }
)

-- return to dashboard
map("n", "<leader>;", "<cmd>Nvdash<cr>", {
  desc = "Return to dashboard",
})

-- diagnostics
map("n", "<Leader>dd", function()
  vim.diagnostic.open_float(nil, { scope = "cursor" })
end, { desc = "Show diagnostic at cursor" })

-- keymaps by telescope
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", {
  desc = "Telescope Find keymaps",
})

map("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", {
  desc = "Telescope Diagnostics",
})

map("n", "<leader>ft", "<cmd>TodoTelescope<cr>", {
  desc = "Telescope Find Todo",
})

map("n", "<leader>fs", "<cmd>Telescope luasnip<cr>", {
  desc = "Telescope Find snippets",
})

-- page movement
map("n", "<C-d>", "<C-d>zz<C-y>", {
  desc = "Jump Half page down",
})

map("n", "<C-u>", "<C-u>zz", {
  desc = "Jump Half page up",
})

map("n", "n", "nzzzv") -- Keeps the search result in the center after jumping to next result
map("n", "N", "Nzzzv") -- Keeps the search result in the center after jumping to previous result

-- tmux navigator
map("n", "<C-h>", "<cmd> NvimTmuxNavigateLeft<CR>", { desc = "window left" })
map("n", "<C-l>", "<cmd> NvimTmuxNavigateRight<CR>", { desc = "window right" })
map("n", "<C-j>", "<cmd> NvimTmuxNavigateDown<CR>", { desc = "window down" })
map("n", "<C-k>", "<cmd> NvimTmuxNavigateUp<CR>", { desc = "window up" })

-- tabufline
map("n", "<leader>X", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, { desc = "Close other buffers" })

-- gitsigns
map("n", "<leader>hn", "<cmd>lua require'gitsigns'.next_hunk()<CR>", { desc = "Next hunk" })
map("n", "<leader>hp", "<cmd>lua require'gitsigns'.prev_hunk()<CR>", { desc = "Previous hunk" })
map("n", "<leader>hs", "<cmd>lua require'gitsigns'.stage_hunk()<CR>", { desc = "Stage hunk" })
map("n", "<leader>hu", "<cmd>lua require'gitsigns'.undo_stage_hunk()<CR>", { desc = "Undo stage hunk" })
map("n", "<leader>hr", "<cmd>lua require'gitsigns'.reset_hunk()<CR>", { desc = "Reset hunk" })
map("n", "<leader>hR", "<cmd>lua require'gitsigns'.reset_buffer()<CR>", { desc = "Reset buffer" })
map("n", "<leader>hp", "<cmd>lua require'gitsigns'.preview_hunk()<CR>", { desc = "Preview hunk" })
map("n", "<leader>hb", "<cmd>lua require'gitsigns'.blame_line()<CR>", { desc = "Blame line" })
map("n", "<leader>hS", "<cmd>lua require'gitsigns'.stage_buffer()<CR>", { desc = "Stage buffer" })
map("n", "<leader>hU", "<cmd>lua require'gitsigns'.reset_buffer_index()<CR>", { desc = "Reset buffer index" })
