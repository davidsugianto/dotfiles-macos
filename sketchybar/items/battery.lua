-- ==============================================================================
-- items/battery.lua — battery percentage, polled from `pmset`.
-- ==============================================================================

local colors = require("colors")
local icons = require("icons")

local battery = sbar.add("item", "battery", {
  position = "right",
  icon = { color = colors.green },
  label = { string = "?%" },
  update_freq = 60,
  click_script = "open 'x-apple.systempreferences:com.apple.Battery-Settings.extension'",
})

local function icon_for(charge, charging)
  if charging then return icons.battery.charging end
  if charge >= 90 then return icons.battery._100 end
  if charge >= 60 then return icons.battery._75 end
  if charge >= 35 then return icons.battery._50 end
  if charge >= 15 then return icons.battery._25 end
  return icons.battery._0
end

local function refresh()
  sbar.exec("pmset -g batt", function(result)
    local charge = tonumber(result:match("(%d+)%%"))
    if not charge then return end
    local charging = result:match("AC Power") ~= nil

    battery:set({
      icon = {
        string = icon_for(charge, charging),
        color = charge <= 15 and colors.red or colors.green,
      },
      label = { string = charge .. "%" },
    })
  end)
end

battery:subscribe({ "routine", "forced", "system_woke", "power_source_change" }, refresh)
