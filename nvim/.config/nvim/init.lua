-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Basic editor settings (make it feel modern)
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Setup lazy.nvim and your plugins
require("lazy").setup({
  spec = {
    -- 🌹 Rose Pine colorscheme
    {
      "rose-pine/neovim",
      name = "rose-pine",
      config = function()
        require("rose-pine").setup({
          variant = "moon",
          disable_background = false,
          styles = { italic = false, bold = false },
        })
        vim.cmd.colorscheme("rose-pine-moon")
      end,
    },

    -- 🧠 Autopairs (auto close brackets, quotes, etc.)
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = function()
        require("nvim-autopairs").setup({
          check_ts = true,
        })
      end,
    },

    -- 💡 Statusline
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("lualine").setup({
          options = {
            theme = "auto",
            section_separators = "",
            component_separators = "",
            icons_enabled = true,
          },
        })
      end,
    },

    -- 🌳 Treesitter: syntax highlighting and more
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      event = { "BufReadPost", "BufNewFile" },
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "lua", "vim", "bash", "python", "javascript", "html", "css" }, -- add what you use
          highlight = { enable = true },
          indent = { enable = true },
          autotag = { enable = true }, -- works with html, jsx, etc. if installed later
        })
      end,
    },

    -- ⚡ Noice.nvim: modern UI for messages, cmdline, and more
    {
      "folke/noice.nvim",
      event = "VeryLazy",
      dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify", -- optional, better notifications
      },
      config = function()
        require("noice").setup({
          lsp = {
            progress = { enabled = true },
            override = {
              ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
              ["vim.lsp.util.stylize_markdown"] = true,
              ["cmp.entry.get_documentation"] = true,
            },
          },
          presets = {
            bottom_search = false,
            command_palette = true,
            long_message_to_split = true,
            inc_rename = false,
            lsp_doc_border = true,
          },
        })
        -- optional: use noice’s notifications
        vim.notify = require("notify")
      end,
    },
  },

  install = { colorscheme = { "rose-pine" } },
  checker = { enabled = true },
})
