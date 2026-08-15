-- ==============================================================================
-- items/cpu.lua — overall CPU load, with a small sparkline history. Polled
-- via `top` rather than a compiled helper (FelixKratz's own dotfiles use a
-- C event provider for this — skipped here to keep this repo dependency-free
-- of anything that needs compiling).
-- ==============================================================================

local colors = require("colors")
local icons = require("icons")

local cpu_graph = sbar.add("graph", "cpu.graph", 32, {
  position = "right",
  graph = { color = colors.green },
  background = { height = 20, drawing = false },
  y_offset = 1,
  click_script = "open -a 'Activity Monitor'",
})

local cpu_label = sbar.add("item", "cpu.label", {
  position = "right",
  icon = { string = icons.cpu, color = colors.green },
  label = { string = "0%", color = colors.subtext0 },
  update_freq = 5,
  click_script = "open -a 'Activity Monitor'",
})

local function refresh()
  sbar.exec("top -l 2 -n 0 -s 0 | grep 'CPU usage' | tail -1", function(top_line)
    local idle = top_line and top_line:match("(%d+%.?%d*)%%%s*idle")
    if not idle then
      return
    end
    local usage = 100 - tonumber(idle)
    cpu_graph:push({ usage / 100 })
    cpu_label:set({ label = string.format("%.0f%%", usage) })
  end)
end

cpu_label:subscribe({ "routine", "forced" }, refresh)
refresh()
