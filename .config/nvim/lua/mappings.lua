require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

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

map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", {
  desc = "Telescope Find keymaps",
})

map("n", "<C-d>", "<C-d>zz<C-y>", {
  desc = "Jump Half page down",
})

map("n", "<C-u>", "<C-u>zz", {
  desc = "Jump Half page up",
})

-- tabufline
map("n", "<leader>X", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, {
  desc = "Close other buffers",
})
