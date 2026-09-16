-- ==============================================================================
-- items/spotify.lua — now-playing widget for Spotify. No native sketchybar
-- event exists for this (unlike volume_change/front_app_switched), so state
-- is polled via AppleScript. The item hides itself entirely when Spotify
-- isn't running, and dims when paused. Click toggles play/pause; scroll
-- skips to the next/previous track.
-- ==============================================================================

local colors = require("colors")
local icons = require("icons")

local spotify = sbar.add("item", "spotify", {
  position = "right",
  icon = { string = icons.spotify, color = colors.green },
  label = { string = "", width = 180, align = "left" },
  update_freq = 2,
  drawing = false,
  click_script = [[osascript -e 'tell application "Spotify" to playpause']],
})

local STATE_QUERY = [[
  if application "Spotify" is running then
    tell application "Spotify"
      if player state is playing or player state is paused then
        return (player state as string) & "|" & (name of current track) & " — " & (artist of current track)
      else
        return "stopped"
      end if
    end tell
  else
    return "not_running"
  end if
]]

local function refresh()
  sbar.exec(string.format("osascript -e '%s'", STATE_QUERY:gsub("'", "'\\''")), function(result)
    result = (result or ""):gsub("[\r\n]+$", "")

    if result == "" or result == "not_running" or result == "stopped" then
      spotify:set({ drawing = false })
      return
    end

    local state, track = result:match("^(%a+)|(.*)$")
    if not state then
      spotify:set({ drawing = false })
      return
    end

    spotify:set({
      drawing = true,
      icon = { color = state == "playing" and colors.green or colors.overlay1 },
      label = { string = track, color = state == "playing" and colors.text or colors.overlay1 },
    })
  end)
end

spotify:subscribe({ "routine", "forced" }, refresh)

spotify:subscribe("mouse.clicked", function()
  sbar.exec([[osascript -e 'tell application "Spotify" to playpause']], refresh)
end)

spotify:subscribe("mouse.scrolled", function(env)
  local delta = tonumber(env.SCROLL_DELTA) or 0
  local track_cmd = delta > 0 and "next track" or "previous track"
  sbar.exec(string.format([[osascript -e 'tell application "Spotify" to %s']], track_cmd), refresh)
end)

refresh()
