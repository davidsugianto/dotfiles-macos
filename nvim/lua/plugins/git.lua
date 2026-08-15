-- ==============================================================================
-- gitsigns — git change indicators in the sign column + hunk navigation.
-- https://github.com/lewis6991/gitsigns.nvim
-- ==============================================================================

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end
      map("n", "]h", gitsigns.next_hunk, "Next hunk")
      map("n", "[h", gitsigns.prev_hunk, "Previous hunk")
      map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
      map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
      map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")
    end,
  },
}
