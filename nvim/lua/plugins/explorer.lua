-- ==============================================================================
-- neo-tree — file explorer sidebar.
-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- ==============================================================================

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  -- lazy = false so the tree is loaded (and shown, via the VimEnter
  -- autocmd below) at startup rather than only on first toggle/command —
  -- gives the "always-docked sidebar" IDE layout instead of an on-demand
  -- panel.
  lazy = false,
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
  },
  opts = {
    close_if_last_window = true,
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = "open_current",
    },
    window = { width = 32, position = "left" },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        require("neo-tree.command").execute({ action = "show", position = "left" })
      end,
    })
  end,
}
