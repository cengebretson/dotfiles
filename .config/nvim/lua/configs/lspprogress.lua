local options = {
  max_size = 100,
  format = function(messages)
    local active_clients = vim.lsp.get_clients { bufnr = 0 }
    if #messages > 0 then
      return table.concat(messages, " ")
    end
    local client_names = {}
    for _, client in ipairs(active_clients) do
      if client and client.name ~= "" then
        table.insert(client_names, 1, client.name)
      end
    end
    return table.concat(client_names, " | ")
  end,
}

return options
