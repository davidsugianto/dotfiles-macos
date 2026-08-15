-- ==============================================================================
-- init.lua — bootstraps SbarLua and assembles the bar in a single config
-- message (begin_config/end_config), then starts the event loop.
-- ==============================================================================

-- Make the SbarLua module discoverable (installed by setup.sh via
-- `make install` from https://github.com/FelixKratz/SbarLua).
package.cpath = package.cpath .. ";" .. os.getenv("HOME") .. "/.local/share/sketchybar_lua/?.so"
sbar = require("sketchybar")

sbar.begin_config()
require("bar")
require("items")
sbar.end_config()

-- Without this, no subscribed Lua callback ever runs.
sbar.event_loop()
