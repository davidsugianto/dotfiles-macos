-- ==============================================================================
-- lualine — Catppuccin Mocha powerline statusline: rounded caps between
-- sections, sharp chevrons between components within a section (same
-- separator language as starship.toml and tmux/tmux.conf.local).
-- https://github.com/nvim-lualine/lualine.nvim
-- ==============================================================================

-- Built via vim.fn.nr2char() rather than typed as literal glyphs — Neovim's
-- Lua runtime is LuaJIT (Lua 5.1), which has no \u{XXXX} string escape (that's
-- a Lua 5.3+/other-interpreter feature — see sketchybar/icons.lua, which can
-- use it because SketchyBar embeds a different Lua). Typing the raw
-- Private-Use-Area character directly risks the silent-drop bug documented
-- in OPERATIONS.md's Known gotchas.
local sep_chevron_right = vim.fn.nr2char(0xE0B0, true)
local sep_chevron_left = vim.fn.nr2char(0xE0B2, true)
local sep_round_right = vim.fn.nr2char(0xE0B4, true)
local sep_round_left = vim.fn.nr2char(0xE0B6, true)

local function lsp_clients()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end
  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return table.concat(names, ", ")
end

local function repo_name()
  local root = vim.fs.root(0, ".git")
  return root and vim.fs.basename(root) or ""
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = function()
    -- lualine has no bundled "catppuccin" theme (that string previously fed
    -- to `theme =` silently fell back to lualine's generic "auto" theme) —
    -- the real one ships inside catppuccin.nvim itself, one file per
    -- flavour, at lualine.themes.catppuccin-<flavour>.
    --
    -- Swap just the normal-mode accent (default: blue) for rosewater —
    -- matches WezTerm's cursor color and tmux's active-window pill.
    -- Insert/visual/replace/command/inactive stay as the theme's defaults.
    local theme = require("lualine.themes.catppuccin-mocha")
    theme.normal.a.bg = "#f5e0dc"
    theme.normal.a.fg = "#1e1e2e"

    return {
      options = {
        theme = theme,
        component_separators = { left = sep_chevron_right, right = sep_chevron_left },
        section_separators = { left = sep_round_right, right = sep_round_left },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { lsp_clients, "filetype" },
        lualine_y = { "progress", "location" },
        lualine_z = { repo_name },
      },
    }
  end,
}
