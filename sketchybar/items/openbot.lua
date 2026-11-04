-- ==============================================================================
-- items/openbot.lua — launcher/status icon for the OpenBot desktop app, drawn
-- with the app's own .icns instead of a font glyph. Full opacity while OpenBot is running, dimmed when it isn't.
-- Click opens (or focuses) the app.
-- ==============================================================================

local ICON = "/Applications/OpenBot.app/Contents/Resources/icon.icns"

local openbot = sbar.add("item", "openbot", {
  position = "right",
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    image = { string = ICON, scale = 0.5, drawing = true },
    color = 0x00000000,
  },
  width = 28,
  update_freq = 10,
  click_script = "open -a OpenBot",
})

local function refresh()
  sbar.exec("pgrep -x OpenBot >/dev/null && echo up || echo down", function(result)
    local running = (result or ""):match("up") ~= nil
    openbot:set({ background = { image = { alpha = running and 1.0 or 0.4 } } })
  end)
end

openbot:subscribe({ "routine", "forced", "system_woke" }, refresh)
refresh()
