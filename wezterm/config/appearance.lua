-- ==============================================================================
-- config/appearance.lua — theme, font, and window chrome.
-- Catppuccin Mocha, matching borders/bordersrc, sketchybar/colors.lua and
-- Neovim's colorscheme.
-- ==============================================================================

local M = {}

function M.apply_to_config(config)
  config.color_scheme = "Catppuccin Mocha"

  config.font = require("wezterm").font_with_fallback({
    "JetBrainsMono Nerd Font",
    "SF Mono",
  })
  config.font_size = 13.5
  config.line_height = 1.1

  -- Minimal chrome: no native title bar, no fat tab bar when there's only
  -- one tab.
  config.window_decorations = "RESIZE"
  config.hide_tab_bar_if_only_one_tab = true
  config.tab_bar_at_bottom = false
  config.use_fancy_tab_bar = false

  config.window_padding = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 8,
  }

  -- Subtle translucency to match the restrained desktop aesthetic; set to
  -- 1.0 if your GPU/battery would rather not blur.
  config.window_background_opacity = 0.96
  config.macos_window_background_blur = 20

  config.cursor_blink_rate = 0
  config.default_cursor_style = "SteadyBar"

  -- Rosewater (Catppuccin Mocha's pale pink) cursor, explicit rather than
  -- relying on the builtin scheme — matches the rest of the repo's
  -- hand-rolled-hex-values convention.
  config.colors = {
    cursor_bg = "#f5e0dc",
    cursor_border = "#f5e0dc",
    cursor_fg = "#1e1e2e",
  }

  config.enable_scroll_bar = false
end

return M
