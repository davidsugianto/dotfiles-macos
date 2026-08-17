-- ==============================================================================
-- nvim-treesitter (main branch) — syntax-aware highlighting, folds, and
-- indent. The main branch is a full rewrite: no more
-- require('nvim-treesitter.configs').setup{ highlight = {...} }; highlighting
-- is Neovim's own vim.treesitter.start(), turned on per-buffer below.
-- Requires Neovim 0.11+ (native LSP) — this repo installs 0.12.x via brew.
-- https://github.com/nvim-treesitter/nvim-treesitter
-- ==============================================================================

local ensure_installed = {
  "bash", "lua", "vim", "vimdoc", "query",
  "markdown", "markdown_inline",
  "json", "toml", "yaml",
  "python", "javascript", "typescript", "tsx",
  "go", "rust", "c", "cpp",
  "terraform", "hcl", "dockerfile",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- the plugin doesn't support lazy-loading
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install(ensure_installed)

    -- No filetype filter: vim.treesitter.start() no-ops harmlessly (via
    -- pcall) for any filetype without an installed parser, which is the
    -- closest match to the old auto_install behavior without reinstalling
    -- a parser on every buffer open.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        if not pcall(vim.treesitter.start) then
          return
        end
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo[0][0].foldmethod = "expr"
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
