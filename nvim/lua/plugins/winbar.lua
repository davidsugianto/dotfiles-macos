-- ==============================================================================
-- dropbar.nvim — winbar breadcrumbs showing the file path and the LSP/
-- treesitter symbol path down to the cursor (e.g. "cpp.cpp > f main").
-- Requires Neovim 0.10+ (this repo runs 0.12.x via brew).
-- https://github.com/Bekaboo/dropbar.nvim
-- ==============================================================================

return {
  "Bekaboo/dropbar.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-telescope/telescope-fzf-native.nvim" },
  keys = {
    {
      "<leader>;",
      function()
        require("dropbar.api").pick()
      end,
      desc = "Pick symbol in winbar",
    },
    {
      "[;",
      function()
        require("dropbar.api").goto_context_start()
      end,
      desc = "Go to start of current context",
    },
    {
      "];",
      function()
        require("dropbar.api").select_next_context()
      end,
      desc = "Select next context",
    },
  },
  opts = {},
}
