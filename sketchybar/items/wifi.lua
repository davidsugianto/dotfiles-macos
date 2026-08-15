-- ==============================================================================
-- items/wifi.lua — Wi-Fi connection state, polled from `ipconfig`.
-- ==============================================================================

local colors = require("colors")
local icons = require("icons")

local wifi = sbar.add("item", "wifi", {
  position = "right",
  icon = { color = colors.sky },
  label = { drawing = false },
  update_freq = 30,
  -- Click to open the Wi-Fi settings pane, so you can switch networks
  -- without hunting through System Settings yourself.
  click_script = "open 'x-apple.systempreferences:com.apple.wifi-settings-extension'",
})

local function refresh()
  sbar.exec("ipconfig getifaddr en0 2>/dev/null", function(ip)
    local connected = ip and ip:gsub("%s+", "") ~= ""
    wifi:set({
      icon = {
        string = connected and icons.wifi.connected or icons.wifi.disconnected,
        color = connected and colors.sky or colors.overlay0,
      },
    })
  end)
end

wifi:subscribe({ "routine", "forced", "system_woke", "wifi_change" }, refresh)
