local opts = {
  lsp = {
    signature = {
      enabled = false,
    },
  },
  presets = {
    command_palette = true, -- position the cmdline and popupmenu together
    lsp_doc_border = true, -- add a border to hover docs and signature help
  },
}

return opts
