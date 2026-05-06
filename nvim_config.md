# Neovim Configuration Backup - 06/05/2026

Tài liệu này chứa toàn bộ nội dung cấu hình Neovim được trích xuất từ `~/.config/nvim/`.

## 1. Cấu hình chính (Core Config)

### init.lua
```lua
require("config.lazy")
```

### lua/config/options.lua
*(File này hiện tại chỉ chứa các comment mặc định)*

### lua/config/keymaps.lua
```lua
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>db", function()
  vim.cmd("cd /home") -- open home
  vim.cmd("Alpha") -- Gọi lại Dashboard
end, { desc = "Return to Dashboard" })

-- Dán trong visual mode mà không làm ghi đè clipboard
vim.keymap.set("x", "p", [["_dP]], { noremap = true, silent = true })
```

### lua/config/lazy.lua
```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false, -- always use the latest git commit
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
```

## 2. Các Plugin tùy chỉnh (Custom Plugins)

### lua/plugins/theme.lua (Everblush Theme)
```lua
return {
  {
    "Everblush/nvim",
    name = "everblush",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("everblush")
      local bg = "#161616"
      -- Cấu hình highlight tùy chỉnh
      vim.api.nvim_set_hl(0, "Normal", { bg = bg })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = bg })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = bg })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = bg })
      vim.api.nvim_set_hl(0, "LineNr", { fg = "#5fb3b3", bg = bg })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#8ccf7e", bg = bg, bold = true })
      -- ... (và các cài đặt highlight khác)
    end,
  },
}
```

### lua/plugins/trans.lua (Transparent Background)
```lua
return {
  "xiyaowong/nvim-transparent",
  config = function()
    require("transparent").setup({
      extra_groups = {
        "Normal", "NormalNC", "EndOfBuffer", "SignColumn", "TelescopeNormal", "TelescopeBorder",
      },
    })
  end,
}
```

### lua/plugins/alpha.lua (Dashboard)
```lua
return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  opts = function()
    local dashboard = require("alpha.themes.dashboard")
    local logo = [[
██▄  ▄██ ▄▄ ▄▄   ██     ▄▄ ▄▄  ▄▄ ▄▄ ▄▄ 
██ ▀▀ ██ ▀███▀   ██     ██ ███▄██ ██▄██ 
██    ██   █     ██████ ██ ██ ▀██ ██ ██ 
    ]]
    dashboard.section.header.val = vim.split(logo, "\n")
    -- Nút bấm điều hướng nhanh...
    return dashboard
  end,
  -- ... (config function)
}
```

### lua/plugins/flutter.lua
```lua
return {
  "akinsho/flutter-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  config = function()
    require("flutter-tools").setup({
      flutter_path = vim.fn.expand("$HOME/flutter/bin/flutter"),
      lsp = { settings = { dart = { completeFunctionCalls = true } } },
    })
  end,
}
```

### lua/plugins/terminal.lua (ToggleTerm)
```lua
return {
  {
    "akinsho/toggleterm.nvim",
    cmd = "ToggleTerm",
    keys = { { "<C-`>", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Toggle vertical terminal" } },
    opts = {
      open_mapping = [[<C-`>]],
      direction = "vertical",
      size = 70,
      -- ...
    },
  },
}
```

### lua/plugins/csscolor.lua (Colorizer)
```lua
return {
  "norcalli/nvim-colorizer.lua",
  config = function()
    require("colorizer").setup({
      user_default_options = { mode = "background", delay = 100, css = { type = "background" } },
      filetypes = { "css", "scss", "html", "javascript", "typescript", "lua" },
    })
  end,
}
```

### lua/plugins/formatting.lua (Conform)
```lua
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      sh = { "shfmt" },
    },
  },
}
```

---
