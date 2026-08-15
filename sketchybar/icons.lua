-- ==============================================================================
-- icons.lua — glyphs used by items/, pulled from the Font Awesome set baked
-- into Nerd Fonts (rendered via settings.font, "JetBrainsMono Nerd Font").
-- Keep this file as the single place to swap icon sets.
-- ==============================================================================

return {
  battery = {
    _100 = "\u{f240}", -- battery-full
    _75 = "\u{f241}",  -- battery-three-quarters
    _50 = "\u{f242}",  -- battery-half
    _25 = "\u{f243}",  -- battery-quarter
    _0 = "\u{f244}",   -- battery-empty
    charging = "\u{f0e7}", -- bolt
  },
  wifi = {
    connected = "\u{f1eb}",    -- wifi
    disconnected = "\u{f05e}", -- circle-slash
  },
  volume = {
    high = "\u{f028}",  -- volume-up
    low = "\u{f027}",   -- volume-down
    muted = "\u{f026}", -- volume-off
  },
  clock = "\u{f017}", -- clock
  apple = "\u{f8ff}", -- Apple logo
  grid = "\u{f00a}",  -- th (app grid, used next to the front-app name)
  cpu = "\u{f2db}",   -- microchip
  package = "\u{f1b2}", -- cube (brew-outdated badge)
  menu = {
    preferences = "\u{f013}", -- gear
    activity = "\u{f002}",    -- search/magnifier
    lock = "\u{f023}",        -- lock
  },
}
