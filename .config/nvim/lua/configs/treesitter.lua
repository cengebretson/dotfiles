local opts = {
  ensure_installed = {
    "vim",
    "lua",
    "vimdoc",
    "html",
    "css",
    "dart",
    "javascript",
    "typescript",
    "tsx",
    "go",
    "python",
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      node_incremental = "v",
      node_decremental = "V",
    },
  },
}

return opts
