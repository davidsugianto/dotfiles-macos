-- ==============================================================================
-- LSP — mason installs language servers; Neovim's native vim.lsp.config /
-- vim.lsp.enable (0.11+) replaces the old require('lspconfig').<server>.setup()
-- pattern, which nvim-lspconfig is deprecating ahead of removal in v3.0.0.
-- https://github.com/neovim/nvim-lspconfig
-- https://github.com/mason-org/mason-lspconfig.nvim
-- ==============================================================================

return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig", -- supplies the bundled per-server default configs
      "hrsh7th/cmp-nvim-lsp",
    },
    opts = {
      -- Add language servers here as you need them; mason installs them
      -- automatically the first time Neovim starts.
      ensure_installed = { "lua_ls", "bashls" },
      automatic_enable = true, -- calls vim.lsp.enable() for every server above
    },
    config = function(_, opts)
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- "*" is a special config name merged as defaults into every server.
      vim.lsp.config("*", { capabilities = capabilities })

      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      -- Config must exist before automatic_enable below turns servers on.
      require("mason-lspconfig").setup(opts)

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
          end
          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "K", vim.lsp.buf.hover, "Hover docs")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>e", vim.diagnostic.open_float, "Line diagnostics")
        end,
      })
    end,
  },
}
