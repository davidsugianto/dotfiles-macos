-- ==============================================================================
-- config/keymaps.lua — keymaps that don't belong to a specific plugin.
-- Plugin-specific keymaps live next to the plugin spec in lua/plugins/.
-- ==============================================================================

local map = vim.keymap.set

-- Move between windows with vim-style hjkl (mirrors AeroSpace's alt-hjkl
-- for focus movement, so the muscle memory carries into split navigation).
map("n", "<C-h>", "<C-w>h", { desc = "Focus window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus window right" })

-- Resize splits
map("n", "<C-Up>", "<cmd>resize +2<CR>")
map("n", "<C-Down>", "<cmd>resize -2<CR>")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>")

-- Buffers (cycling + delete keymaps live in plugins/bufferline.lua)

-- Clear search highlight
map("n", "<esc>", "<cmd>nohlsearch<CR>")

-- Keep the cursor centered while scrolling/searching
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Move selected lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Save / quit
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
