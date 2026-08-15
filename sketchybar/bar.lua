-- ==============================================================================
-- bar.lua — top-level bar geometry, equivalent to the `--bar` domain.
-- ==============================================================================

local colors = require("colors")
local settings = require("settings")

sbar.bar({
  height = settings.bar_height,
  color = colors.bar.bg,
  border_color = colors.bar.border,
  border_width = 1,
  corner_radius = 9,
  margin = 8,   -- floating pill, inset from the screen edges
  y_offset = 5,
  shadow = true,
  padding_left = 6,
  padding_right = 6,
  position = "top",
  sticky = true,
  topmost = "window",
})

-- Defaults applied to every item unless overridden.
sbar.default({
  updates = "when_shown",
  icon = {
    font = { family = settings.font.text, size = 12.0 },
    color = colors.text,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  label = {
    font = { family = settings.font.text, size = 12.0 },
    color = colors.text,
    padding_left = settings.paddings,
    padding_right = settings.paddings,
  },
  background = {
    height = 26,
    corner_radius = 6,
    border_width = 0,
  },
  padding_left = settings.paddings,
  padding_right = settings.paddings,
})
