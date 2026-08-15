-- ==============================================================================
-- wezterm.lua — entry point. Config is split into config/ modules so each
-- concern (appearance, general behavior, keys) is easy to find and tweak.
-- https://wezfurlong.org/wezterm/config/files.html
--
-- Symlinked to ~/.config/wezterm/wezterm.lua by setup.sh. WezTerm adds this
-- file's directory to package.path, so `require("config.x")` resolves
-- relative to this repo's wezterm/ folder.
-- ==============================================================================

local wezterm = require("wezterm")
local config = wezterm.config_builder()

require("config.appearance").apply_to_config(config)
require("config.general").apply_to_config(config)
require("config.keys").apply_to_config(config)

return config
