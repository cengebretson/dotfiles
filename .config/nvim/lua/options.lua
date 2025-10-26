require "nvchad.options"

local o = vim.o

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
