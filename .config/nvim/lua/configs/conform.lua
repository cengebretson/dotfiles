local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "biome", "biome-organize-imports" },
    javascriptreact = { "biome", "biome-organize-imports" },
    typescript = { "biome", "biome-organize-imports" },
    typescriptreact = { "biome", "biome-organize-imports" },
    json = { "biome" },
    html = { "biome" },
    css = { "biome" },
    java = { "google-java-format" },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    python = { "ruff_organize_imports", "ruff_format" },
    bash = { "beautysh" },
    yaml = { "yamlfix" },
    toml = { "taplo" },
    sh = { "shellcheck" },
    go = { "gofmt" },
    xml = { "xmlformat" },
    xslt = { "xmlformat" },
    dart = { "dart_format" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
