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
vim.opt.number = true             -- show line numbers
vim.opt.relativenumber = true     -- relative line numbers
vim.opt.mouse = "a"               -- enable mouse
vim.opt.clipboard = "unnamedplus" -- use system clipboard
vim.opt.breakindent = true        -- wrapped line indent
vim.opt.tabstop = 2               -- number of spaces for a tab
vim.opt.shiftwidth = 2            -- spaces for indentation
vim.opt.expandtab = true          -- use spaces instead of tabs
vim.opt.smartindent = true        -- smarter auto indent
vim.opt.ignorecase = true         -- case-insensitive search...
vim.opt.smartcase = true          -- ...unless capital letters
vim.opt.termguicolors = true      -- true color support
vim.opt.signcolumn = "yes"        -- always show sign column
vim.opt.cursorline = true         -- highlight current line
vim.opt.wrap = false              -- no soft wrapping
vim.opt.scrolloff = 8             -- minimal lines around cursor
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
          check_ts = true, -- integrates with treesitter if installed later
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
  },

  install = { colorscheme = { "rose-pine" } },
  checker = { enabled = true },
})
