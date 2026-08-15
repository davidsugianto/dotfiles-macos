-- ==============================================================================
-- items/init.lua — load order matters: left-side items should be added
-- before right-side items, and within "right", first-added ends up
-- leftmost in that cluster (clock is added last so it stays at the far
-- right edge).
-- ==============================================================================

local colors = require("colors")

require("items.apple")
require("items.aerospace")
require("items.front_app")

require("items.cpu")
require("items.volume")
require("items.battery")

-- Groups volume + battery into one pill, matching the reference layout.
sbar.add("bracket", "widgets.bracket", { "volume", "battery" }, {
  background = {
    color = colors.surface0,
    border_color = colors.surface1,
    border_width = 1,
    corner_radius = 9,
    height = 28,
  },
})

require("items.wifi")
require("items.brew")
require("items.clock")
