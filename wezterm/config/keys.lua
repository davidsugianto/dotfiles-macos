-- ==============================================================================
-- config/keys.lua — i3-inspired keybindings: a tmux-style leader for pane
-- management (vim-style hjkl), CMD+number for tabs. Alt is left untouched
-- since AeroSpace owns it at the OS level.
-- ==============================================================================

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply_to_config(config)
  config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

  config.keys = {
    -- Panes — split (i3-style mnemonics: v = vertical split, s = horizontal split)
    { key = "v", mods = "LEADER", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
    { key = "s", mods = "LEADER", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },

    -- Panes — focus movement (vim-style)
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

    -- Panes — resize (repeatable within the leader timeout)
    { key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
    { key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
    { key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
    { key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

    -- Tabs
    { key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = true }) },
    { key = "1", mods = "CMD", action = act.ActivateTab(0) },
    { key = "2", mods = "CMD", action = act.ActivateTab(1) },
    { key = "3", mods = "CMD", action = act.ActivateTab(2) },
    { key = "4", mods = "CMD", action = act.ActivateTab(3) },
    { key = "5", mods = "CMD", action = act.ActivateTab(4) },
    { key = "6", mods = "CMD", action = act.ActivateTab(5) },
    { key = "7", mods = "CMD", action = act.ActivateTab(6) },
    { key = "8", mods = "CMD", action = act.ActivateTab(7) },
    { key = "9", mods = "CMD", action = act.ActivateTab(8) },
    { key = "[", mods = "CMD", action = act.ActivateTabRelative(-1) },
    { key = "]", mods = "CMD", action = act.ActivateTabRelative(1) },

    -- Font size
    { key = "=", mods = "CMD", action = act.IncreaseFontSize },
    { key = "-", mods = "CMD", action = act.DecreaseFontSize },
    { key = "0", mods = "CMD", action = act.ResetFontSize },

    -- Config
    { key = "r", mods = "LEADER", action = act.ReloadConfiguration },
  }
end

return M
