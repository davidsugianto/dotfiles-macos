-- ==============================================================================
-- config/general.lua — non-visual behavior: shell, scrollback, updates.
-- ==============================================================================

local M = {}

function M.apply_to_config(config)
  config.scrollback_lines = 10000
  config.adjust_window_size_when_changing_font_size = false

  -- WezTerm re-reads this config on save automatically; this just adds a
  -- confirmation toast so a reload is visible.
  config.automatically_reload_config = true

  config.check_for_updates = false

  config.audible_bell = "Disabled"

  -- macOS: use the login shell so PATH/env from .zshrc is available.
  config.default_prog = { "/bin/zsh", "-l" }
end

return M
