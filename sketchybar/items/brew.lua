-- ==============================================================================
-- items/brew.lua — count of outdated Homebrew packages, click to see which
-- ones. Refreshed infrequently since `brew outdated` can hit the network.
-- ==============================================================================

local colors = require("colors")
local icons = require("icons")

local brew = sbar.add("item", "brew", {
  position = "right",
  icon = { string = icons.package, color = colors.peach },
  label = { string = "…" },
  update_freq = 1800, -- 30 minutes
})

local popup_items = {}

local function clear_popup()
  for _, item in ipairs(popup_items) do
    item:remove()
  end
  popup_items = {}
end

local function rebuild_popup(packages)
  clear_popup()

  if #packages == 0 then
    local item = sbar.add("item", "brew.popup.none", {
      position = "popup." .. brew.name,
      icon = { drawing = false },
      label = { string = "Everything up to date", width = 180, align = "left" },
    })
    table.insert(popup_items, item)
    return
  end

  for i, pkg in ipairs(packages) do
    local item = sbar.add("item", "brew.popup." .. i, {
      position = "popup." .. brew.name,
      icon = { drawing = false },
      label = { string = pkg, width = 180, align = "left" },
    })
    table.insert(popup_items, item)
  end
end

local function refresh()
  sbar.exec("command -v brew >/dev/null 2>&1 && brew outdated 2>/dev/null", function(result)
    local packages = {}
    for line in (result or ""):gmatch("[^\r\n]+") do
      local name = line:match("^(%S+)")
      if name then
        table.insert(packages, name)
      end
    end
    brew:set({ label = { string = tostring(#packages) } })
    rebuild_popup(packages)
  end)
end

brew:subscribe({ "routine", "forced" }, refresh)

brew:subscribe("mouse.clicked", function()
  brew:set({ popup = { drawing = "toggle" } })
end)

brew:subscribe("mouse.exited.global", function()
  brew:set({ popup = { drawing = false } })
end)

refresh()
