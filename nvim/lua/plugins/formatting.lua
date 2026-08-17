-- ==============================================================================
-- conform.nvim — format-on-save, dispatched per filetype to the tools mason
-- installs (see plugins/mason-tools.lua). This is the "prettier" layer: it
-- shells out to real formatter binaries rather than asking the LSP server
-- to format, so formatting stays consistent even across servers that don't
-- implement textDocument/formatting well.
-- https://github.com/stevearc/conform.nvim
-- ==============================================================================

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  opts = {
    -- This repo standardizes on OpenTofu (`tofu`) over HashiCorp's
    -- `terraform` CLI (see development-tools.sh) — conform's bundled
    -- "terraform_fmt" formatter hardcodes the `terraform` binary, so this
    -- defines an equivalent that shells out to `tofu fmt` instead.
    formatters = {
      tofu_fmt = {
        command = "tofu",
        args = { "fmt", "-" },
        stdin = true,
      },
    },
    formatters_by_ft = {
      lua = { "stylua" },
      go = { "goimports" },
      python = { "ruff_format" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      terraform = { "tofu_fmt" },
      ["terraform-vars"] = { "tofu_fmt" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_fallback = true,
    },
  },
}
