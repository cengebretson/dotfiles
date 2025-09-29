local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    svelte = { "prettierd", "prettier", stop_after_first = true },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    graphql = { "prettierd", "prettier", stop_after_first = true },
    java = { "google-java-format" },
    kotlin = { "ktlint" },
    -- ruby = { "standardrb" },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    erb = { "htmlbeautifier" },
    html = { "htmlbeautifier" },
    python = { "ruff" },
    bash = { "beautysh" },
    proto = { "buf" },
    rust = { "rustfmt" },
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
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
