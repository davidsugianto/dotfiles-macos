-- ==============================================================================
-- items/volume.lua — output volume, driven by sketchybar's built-in
-- `volume_change` event (no polling needed).
-- ==============================================================================

local colors = require("colors")
local icons = require("icons")

local volume = sbar.add("item", "volume", {
  position = "right",
  icon = { color = colors.peach },
  label = { drawing = false },
  -- Click opens Sound settings; scroll up/down nudges volume 5% per notch.
  click_script = "open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'",
})

volume:subscribe("mouse.scrolled", function(env)
  local delta = tonumber(env.SCROLL_DELTA) or 0
  local step = delta > 0 and 5 or -5
  sbar.exec(string.format(
    "osascript -e 'set volume output volume (output volume of (get volume settings) + (%d))'", step
  ))
end)

local function icon_for(vol)
  if vol == 0 then return icons.volume.muted end
  if vol < 50 then return icons.volume.low end
  return icons.volume.high
end

volume:subscribe("volume_change", function(env)
  local vol = tonumber(env.INFO) or 0
  volume:set({ icon = { string = icon_for(vol) } })
end)
