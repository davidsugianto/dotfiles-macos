-- ==============================================================================
-- items/apple.lua — Apple logo, far left. Click opens a small popup menu:
-- Preferences, Activity Monitor, Lock Screen.
-- ==============================================================================

local colors = require("colors")
local icons = require("icons")

local apple = sbar.add("item", "apple", {
  icon = {
    string = icons.apple,
    font = { size = 16.0 },
    padding_left = 10,
    padding_right = 10,
    color = colors.text,
  },
  label = { drawing = false },
})

local function popup_entry(id, icon, label, cmd)
  local entry = sbar.add("item", "apple.popup." .. id, {
    position = "popup." .. apple.name,
    icon = { string = icon, width = 20, align = "center", color = colors.subtext1 },
    label = { string = label, width = 120, align = "left" },
    click_script = cmd .. "; sketchybar --set apple popup.drawing=off",
  })

  entry:subscribe("mouse.entered", function()
    entry:set({ background = { color = colors.surface1, corner_radius = 5, height = 24 } })
  end)
  entry:subscribe("mouse.exited", function()
    entry:set({ background = { color = colors.transparent } })
  end)
end

popup_entry("preferences", icons.menu.preferences, "Preferences", "open -a 'System Settings'")
popup_entry("activity", icons.menu.activity, "Activity", "open -a 'Activity Monitor'")
popup_entry("lock", icons.menu.lock, "Lock Screen",
  [[/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend]])

apple:subscribe("mouse.clicked", function()
  apple:set({ popup = { drawing = "toggle" } })
end)

apple:subscribe("mouse.exited.global", function()
  apple:set({ popup = { drawing = false } })
end)
