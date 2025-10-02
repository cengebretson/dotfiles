local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    svelte = { "prettierd", "prettier", stop_after_first = true },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    java = { "google-java-format" },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    html = { "htmlbeautifier" },
    python = { "ruff_organize_imports", "ruff_format" },
    bash = { "beautysh" },
    yaml = { "yamlfix" },
    toml = { "taplo" },
    css = { "prettierd", "prettier", stop_after_first = true },
    scss = { "prettierd", "prettier", stop_after_first = true },
    sh = { "shellcheck" },
    go = { "gofmt" },
    xml = { "xmllint" },
    dart = { "dart_format" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
