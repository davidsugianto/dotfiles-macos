-- ==============================================================================
-- mason-tool-installer — ensures non-LSP mason packages (formatters,
-- linters) are installed too. mason-lspconfig's ensure_installed (see
-- plugins/lsp.lua) only manages LSP servers; this covers everything conform
-- (plugins/formatting.lua) and nvim-lint (plugins/linting.lua) shell out to.
-- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
-- ==============================================================================

return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "mason-org/mason.nvim" },
  event = "VeryLazy",
  opts = {
    ensure_installed = {
      "stylua", -- lua
      "goimports", -- go
      "shfmt", "shellcheck", -- bash
      "golangci-lint", -- go
      "tflint", -- terraform
      "yamllint", -- yaml
      "prettier", -- js/ts/json/yaml/markdown
    },
  },
}
