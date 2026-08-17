-- ==============================================================================
-- bufferline — tab bar of open buffers along the top, offset to sit next
-- to the neo-tree sidebar (matches the "Neo-tree" header shown in the
-- explorer's own screenshot).
-- https://github.com/akinsho/bufferline.nvim
-- ==============================================================================

return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  keys = {
    { "<S-l>", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
    { "<leader>bp", "<cmd>BufferLinePick<CR>", desc = "Pick buffer" },
    { "<leader>bd", "<cmd>bdelete<CR>", desc = "Delete buffer" },
  },
  opts = {
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      always_show_bufferline = true,
      show_buffer_close_icons = true,
      show_close_icon = false,
      separator_style = "thin",
      offsets = {
        {
          filetype = "neo-tree",
          text = "Neo-tree",
          highlight = "Directory",
          text_align = "left",
          separator = true,
        },
      },
    },
  },
}
