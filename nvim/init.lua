-- ==============================================================================
-- init.lua — entry point. Bootstraps lazy.nvim, then loads config/ modules
-- and plugins/ specs. Symlinked to ~/.config/nvim by setup.sh.
-- ==============================================================================

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
