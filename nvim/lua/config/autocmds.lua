-- ==============================================================================
-- config/autocmds.lua — small editor behaviors that aren't tied to a plugin.
-- ==============================================================================

local augroup = vim.api.nvim_create_augroup("user_autocmds", {})

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})

-- Restore cursor to last edit position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Trim trailing whitespace on save.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Neovim's persistent-undo filenames are the buffer's absolute path with
-- every '/' turned into '%' (see :h undodir) — no truncation. This user's
-- terragrunt trees nest deep enough (org/env/folder/project/...) that the
-- escaped name routinely exceeds APFS's 255-byte filename limit, which
-- fails with E828 on every save. For those paths only, skip the native
-- undofile and persist under a fixed-length sha256 hash instead.
local function undo_path_too_long(path)
  return path ~= "" and #path > 240
end

local function hashed_undo_file(path)
  local dir = vim.split(vim.o.undodir, ",")[1]
  return dir .. "/hashed-" .. vim.fn.sha256(path)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = augroup,
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    if vim.bo[args.buf].buftype ~= "" or not undo_path_too_long(path) then
      return
    end
    vim.bo[args.buf].undofile = false
    local undo_file = hashed_undo_file(path)
    if vim.fn.filereadable(undo_file) == 1 then
      vim.cmd("silent! rundo " .. vim.fn.fnameescape(undo_file))
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    if vim.bo[args.buf].buftype ~= "" or not undo_path_too_long(path) then
      return
    end
    vim.cmd("silent! wundo! " .. vim.fn.fnameescape(hashed_undo_file(path)))
  end,
})
