return function(_, opts)
  -- Adapted from:
  -- https://github.com/catppuccin/tmux/discussions/317#discussioncomment-14030975
  local auto = require "lualine.themes.auto"
  local colors = require("catppuccin.palettes").get_palette "frappe"

  -- TODO: move this to autocommand, and make it transparent for nvdash
  vim.api.nvim_set_hl(0, "StatusLine", { bg = colors.mantle })

  local function separator()
    return {
      function()
        return "󰇝"
      end,
      color = { fg = colors.surface2, bg = "NONE", gui = "bold" },
      padding = { left = 0, right = 0 },
    }
  end

  local function custom_branch()
    local gitsigns = vim.b.gitsigns_head
    local branch = gitsigns
    if branch == nil or branch == "" then
      return ""
    else
      return " " .. branch
    end
  end

  local modes = { "normal", "insert", "visual", "replace", "command", "inactive", "terminal" }
  for _, mode in ipairs(modes) do
    if auto[mode] and auto[mode].c then
      auto[mode].c.bg = "NONE"
    end
  end

  opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
    theme = auto,
    component_separators = "",
    section_separators = "",
    globalstatus = true,
    -- disabled_filetypes = { statusline = { "nvdash" } },
  })

  opts.sections = {
    lualine_a = {
      {
        "mode",
        fmt = function(str)
          local reg = vim.fn.reg_recording()
          if reg ~= "" then
            reg = "@" .. reg .. " "
          end
          return reg .. str:sub(1, 1)
        end,
        padding = { left = 1, right = 1 },
      },
    },
    lualine_b = {
      {
        custom_branch,
        color = { fg = colors.green, bg = "none" },
        padding = { left = 1, right = 1 },
      },
      {
        "diff",
        colored = true,
        diff_color = {
          added = { fg = colors.teal, bg = "none", gui = "bold" },
          modified = { fg = colors.yellow, bg = "none", gui = "bold" },
          removed = { fg = colors.red, bg = "none", gui = "bold" },
        },
        source = nil,
        padding = { left = 0, right = 1 },
      },
      separator(),
    },
    lualine_c = {
      {
        "filetype",
        icon_only = true,
        colored = false,
        color = { fg = colors.blue, bg = "none" },
        padding = { left = 1, right = 0 },
      },
      {
        "filename",
        file_status = true,
        path = 4,
        shorting_target = 20,
        symbols = {
          modified = "[+]",
          readonly = "[-]",
          unnamed = "[?]",
          newfile = "[!]",
        },
        color = { fg = colors.blue, bg = "none" },
        padding = { left = 0, right = 1 },
      },
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        sections = { "error", "warn", "info", "hint" },
        diagnostics_color = {
          error = function()
            local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
            return { fg = (count == 0) and colors.green or colors.red, bg = "none", gui = "bold" }
          end,
          warn = function()
            local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
            return { fg = (count == 0) and colors.green or colors.yellow, bg = "none", gui = "bold" }
          end,
          info = function()
            local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
            return { fg = (count == 0) and colors.green or colors.blue, bg = "none", gui = "bold" }
          end,
          hint = function()
            local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
            return { fg = (count == 0) and colors.green or colors.teal, bg = "none", gui = "bold" }
          end,
        },
        symbols = {
          error = "󰅚 ",
          warn = "󰀪 ",
          info = "󰋽 ",
          hint = "󰌶 ",
        },
        colored = true,
        update_in_insert = false,
        always_visible = false,
        padding = { left = 0, right = 1 },
      },
    },
    lualine_x = {},
    lualine_y = {
      {
        function()
          return require("lsp-progress").progress()
        end,
        color = { fg = colors.yellow, bg = "none" },
        padding = { left = 1, right = 1 },
        icon = { " ", align = "right" },
      },
    },
    lualine_z = {
      separator(),
      {
        function()
          return " " .. vim.fn.line "." .. ":" .. vim.fn.col "." -- Example with line/column icon
        end,
        color = { fg = colors.red, bg = "none" },
        padding = { left = 1, right = 1 },
      },
    },
  }

  return opts
end
