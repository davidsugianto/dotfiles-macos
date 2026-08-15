-- ==============================================================================
-- items/front_app.lua — name of the focused app, left of the workspaces.
-- Requires `sketchybar --set front_app` events, which are enabled by
-- `sketchybar --config-app_switch on` (default) picking up NSWorkspace
-- notifications; no extra setup needed.
-- ==============================================================================

local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

local front_app = sbar.add("item", "front_app", {
  icon = {
    string = icons.grid,
    color = colors.mauve,
    padding_right = settings.paddings,
  },
  label = {
    font = { family = settings.font.text, style = settings.font.style_map["Semibold"], size = 12.0 },
    color = colors.text,
  },
  updates = true,
  -- Click to hide the focused app (cmd-h equivalent).
  click_script = [[osascript -e 'tell application "System Events" to set visible of first process whose frontmost is true to false']],
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO } })
end)
