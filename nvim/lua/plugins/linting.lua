-- ==============================================================================
-- nvim-lint — linters for filetypes whose LSP server doesn't already
-- surface these diagnostics. Python (ruff) and JS/TS (eslint) get lint
-- diagnostics straight from their LSP servers in plugins/lsp.lua, so they're
-- deliberately not duplicated here.
-- https://github.com/mfussenegger/nvim-lint
-- ==============================================================================

return {
  "mfussenegger/nvim-lint",
  event = { "BufWritePost", "BufReadPost", "InsertLeave" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      go = { "golangcilint" },
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      terraform = { "tflint" },
      yaml = { "yamllint" },
    }

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
