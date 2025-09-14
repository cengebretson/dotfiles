return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "nvzone/floaterm",
    dependencies = "nvzone/volt",
    opts = {},
    cmd = "FloatermToggle",
  },

  {
    "nvzone/typr",
    dependencies = "nvzone/volt",
    opts = {},
    cmd = { "Typr", "TyprStats" },
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "stevearc/oil.nvim",
    opts = {},
    event = "VeryLazy",
    cmd = "Oil",
    config = function()
      require "configs.oil"
    end,
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = {
          jump_labels = true,
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    },
    config = function()
      vim.api.nvim_command "hi clear FlashLabel"
      vim.api.nvim_command "hi FlashLabel guibg=#A25772 guifg=#EEF5FF"
    end,
  },

  { "nvim-mini/mini.ai", lazy = false, opts = {} },

  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    opts = {},
  },

  {
    "kevinhwang91/nvim-ufo",
    event = "BufRead",
    dependencies = "kevinhwang91/promise-async",
    config = function()
      require "configs.ufo"
    end,
  },

  { "tpope/vim-repeat", event = "VeryLazy" },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    event = "VeryLazy",
    opts = {},
    ft = { "markdown", "codecompanion" },
    dependencies = { "ynvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
  },

  {
    "kylechui/nvim-surround",
    lazy = false,
    config = function()
      require("nvim-surround").setup {}
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
      },
    },
  },
}
