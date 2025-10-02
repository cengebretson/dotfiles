require "nvchad.mappings"

local map = vim.keymap.set

-- overwriting the same lines in NvChad mapping file, in order to add 'async = true'
map("n", "<leader>fm", function()
  require("conform").format { async = true, lsp_fallback = true }
end, { desc = "custom format files" })

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

-- tmux navigator
map("n", "<C-h>", "<cmd> NvimTmuxNavigateLeft<CR>", { desc = "window left" })
map("n", "<C-l>", "<cmd> NvimTmuxNavigateRight<CR>", { desc = "window right" })
map("n", "<C-j>", "<cmd> NvimTmuxNavigateDown<CR>", { desc = "window down" })
map("n", "<C-k>", "<cmd> NvimTmuxNavigateUp<CR>", { desc = "window up" })

-- tabufline
map("n", "<leader>X", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, { desc = "Close other buffers" })
