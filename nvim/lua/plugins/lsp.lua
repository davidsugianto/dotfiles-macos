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
      "b0o/schemastore.nvim", -- JSON/YAML schema catalog (package.json, GH Actions, k8s, ...)
    },
    opts = {
      -- Add language servers here as you need them; mason installs them
      -- automatically the first time Neovim starts.
      ensure_installed = {
        "lua_ls", "bashls", "clangd",
        "gopls", -- Go
        "ts_ls", "eslint", -- Node.js/JavaScript/TypeScript
        "pyright", "ruff", -- Python (types + fast linting)
        "yamlls", -- YAML
        "jsonls", -- JSON (package.json, tsconfig, ...)
        "terraformls", -- Terraform/HCL
      },
      automatic_enable = true, -- calls vim.lsp.enable() for every server above
    },
    config = function(_, opts)
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- "*" is a special config name merged as defaults into every server.
      vim.lsp.config("*", { capabilities = capabilities })

      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      vim.lsp.config("gopls", {
        settings = { gopls = { staticcheck = true } },
      })

      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" }, -- disable built-in fetch, use schemastore.nvim instead
            schemas = require("schemastore").yaml.schemas(),
          },
        },
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
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
