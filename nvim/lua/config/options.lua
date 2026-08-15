-- ==============================================================================
-- config/options.lua — core editor settings.
-- ==============================================================================

local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.scrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Files
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"
opt.swapfile = false
opt.backup = false
opt.updatetime = 250
opt.timeoutlen = 400

-- Clipboard — shares the system clipboard by default (macOS pbcopy/pbpaste).
opt.clipboard = "unnamedplus"

-- Completion UI
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12

opt.mouse = "a"
