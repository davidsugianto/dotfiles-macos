-- ==============================================================================
-- Catppuccin — matches WezTerm, SketchyBar, and JankyBorders (Mocha flavor).
-- https://github.com/catppuccin/nvim
-- ==============================================================================

return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- load before anything that reads highlight groups
  opts = {
    flavour = "mocha",
    integrations = {
      cmp = true,
      gitsigns = true,
      telescope = true,
      treesitter = true,
      native_lsp = { enabled = true },
      which_key = true,
      bufferline = true,
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
