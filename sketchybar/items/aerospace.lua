-- ==============================================================================
-- items/aerospace.lua — workspace indicator wired to AeroSpace, with running
-- apps shown as icons under each workspace via sketchybar-app-font
-- (font-sketchybar-app-font cask + icon_map.lua, both installed by setup.sh).
--
-- AeroSpace's `exec-on-workspace-change` (see aerospace/aerospace.toml)
-- triggers the custom "aerospace_workspace_change" event below on every
-- workspace switch, passing the newly focused workspace as FOCUSED_WORKSPACE.
-- ==============================================================================

local colors = require("colors")
local settings = require("settings")

sbar.add("event", "aerospace_workspace_change")

-- icon_map.lua is vendored by setup.sh (downloaded from the
-- sketchybar-app-font release, not committed — it's ~800 lines of
-- generated app-name -> ligature data).
local icon_map_path = os.getenv("HOME") .. "/.local/share/sketchybar/icon_map.lua"
local icon_map_ok, icon_map = pcall(dofile, icon_map_path)
if not icon_map_ok then
  icon_map = {}
end

local WORKSPACE_COUNT = 9
local workspaces = {}
local bracket_members = {}

for i = 1, WORKSPACE_COUNT do
  local workspace = sbar.add("item", "aerospace.workspace." .. i, {
    icon = {
      string = tostring(i),
      padding_left = 8,
      padding_right = 4,
      color = colors.subtext0,
    },
    label = {
      string = "",
      drawing = false,
      font = "sketchybar-app-font:Regular:12.0",
      padding_left = 2,
      padding_right = 8,
      color = colors.text,
    },
    background = {
      color = colors.transparent,
      border_color = colors.transparent,
      corner_radius = 5,
      height = 24,
    },
    click_script = "aerospace workspace " .. i,
  })

  workspaces[i] = workspace
  bracket_members[i] = workspace.name

  workspace:subscribe("aerospace_workspace_change", function(env)
    local focused = env.FOCUSED_WORKSPACE == tostring(i)
    workspace:set({
      icon = { color = focused and colors.base or colors.subtext0 },
      background = {
        color = focused and colors.mauve or colors.transparent,
        border_color = focused and colors.mauve or colors.transparent,
      },
    })
  end)
end

-- Wraps every workspace item in one pill, matching a single grouped bracket
-- instead of loose individual items.
sbar.add("bracket", "aerospace.bracket", bracket_members, {
  background = {
    color = colors.surface0,
    border_color = colors.surface1,
    border_width = 1,
    corner_radius = 9,
    height = 28,
  },
})

-- Refreshes which apps show under each workspace. One `aerospace` call
-- covering every window, fanned out locally, instead of one call per
-- workspace.
local function refresh_apps()
  sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null", function(result)
    local apps_by_workspace = {}
    for i = 1, WORKSPACE_COUNT do
      apps_by_workspace[i] = {}
    end

    for line in (result or ""):gmatch("[^\r\n]+") do
      local ws_str, app = line:match("^(%d+)|(.+)$")
      local ws = ws_str and tonumber(ws_str)
      if ws and apps_by_workspace[ws] and app then
        table.insert(apps_by_workspace[ws], app)
      end
    end

    for i = 1, WORKSPACE_COUNT do
      local ligatures = {}
      for _, app in ipairs(apps_by_workspace[i]) do
        table.insert(ligatures, icon_map[app] or ":default:")
      end
      local label = table.concat(ligatures, " ")
      workspaces[i]:set({ label = { string = label, drawing = label ~= "" } })
    end
  end)
end

sbar.add("item", "aerospace.poller", { drawing = false, updates = true, update_freq = 15 })
  :subscribe({ "routine", "forced", "front_app_switched", "aerospace_workspace_change" }, refresh_apps)

-- Seed the initial focus highlight and app icons on bar startup, since the
-- events above only fire on subsequent changes.
sbar.exec("aerospace list-workspaces --focused", function(focused)
  focused = (focused or ""):gsub("%s+", "")
  sbar.trigger("aerospace_workspace_change", { FOCUSED_WORKSPACE = focused })
end)
refresh_apps()
