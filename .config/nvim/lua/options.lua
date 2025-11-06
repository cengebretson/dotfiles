require "nvchad.options"

local o = vim.o
local g = vim.g

-- turn off wrappiung
o.wrap = false

-- show cursorline
o.cursorline = true
o.cursorlineopt = "both"

-- border on windows
o.winborder = "rounded"

-- enable relatiove number
o.relativenumber = true

-- disable swap file
o.swapfile = false

-- show search matches as you type
o.incsearch = true

-- show live preview of substitute command
o.inccommand = "split"

-- This example shows settings for Neovide
--
if vim.g.neovide then
  -- Set transparency and background color (title bar color)
  g.neovide_opacity = 0.9

  -- Cursor Animation: Enable a specific cursor animation
  g.neovide_cursor_animation_length = 0.05
  g.neovide_cursor_trail_size = 0.5
  g.neovide_window_blurred = true -- macOS only

  -- Transparency for floating windows and popups
  o.winblend = 10 -- Opaque floating windows
  o.pumblend = 10 -- Opaque popup menu
  o.linespace = 12

  vim.g.neovide_scale_factor = 1.0
  local change_scale_factor = function(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
  end
  vim.keymap.set("n", "<C-=>", function()
    change_scale_factor(1.1)
  end)
  vim.keymap.set("n", "<C-->", function()
    change_scale_factor(1 / 1.1)
  end)

  vim.g.neovide_padding_top = 10
  vim.g.neovide_padding_bottom = 2

  vim.keymap.set("n", "<D-s>", ":w<CR>") -- Save
  vim.keymap.set("v", "<D-c>", '"+y') -- Copy
  vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
  vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
  vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode
end
