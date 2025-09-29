return {

  {
    "stevearc/quicker.nvim",
    ft = "qf",
    opts = {},
    keys = {
      {
        ">",
        function()
          require("quicker").expand { before = 2, after = 2, add_to_existing = true }
        end,
        desc = "Expand quickfix context",
      },
      {
        "<",
        function()
          require("quicker").collapse()
        end,
        desc = "Collapse quickfix context",
      },
    },
  },

  { "Bakudankun/PICO-8.vim", opts = {} },

  { "linrongbin16/lsp-progress.nvim", opts = require "configs.lspprogress" },

  {
    "alexghergh/nvim-tmux-navigation",
    lazy = false,
    config = function()
      local nvim_tmux_nav = require "nvim-tmux-navigation"
      nvim_tmux_nav.setup {
        disable_when_zoomed = true, -- defaults to false
      }
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    opts = require "configs.lualine",
  },

  {
    "nvzone/timerly",
    dependencies = "nvzone/volt",
    cmd = "TimerlyToggle",
    opts = {}, -- optional
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
    },
  },

  { "folke/neodev.nvim", opts = {} },

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
    event = "VeryLazy",
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {},
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
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
        "dart",
        "javascript",
        "typescript",
        "go",
        "python",
      },
    },
  },
}
