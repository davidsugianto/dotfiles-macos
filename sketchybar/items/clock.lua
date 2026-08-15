-- ==============================================================================
-- items/clock.lua — simple date/time display, right-most item.
-- ==============================================================================

local colors = require("colors")
local icons = require("icons")

local clock = sbar.add("item", "clock", {
  position = "right",
  icon = { string = icons.clock, color = colors.lavender },
  label = { string = os.date("%a %d %b  %H:%M") },
  update_freq = 10,
  click_script = "open -a Calendar",
})

clock:subscribe({ "routine", "forced" }, function()
  clock:set({ label = os.date("%a %d %b  %H:%M") })
end)
