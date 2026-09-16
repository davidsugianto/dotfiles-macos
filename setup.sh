#!/usr/bin/env bash
# ==============================================================================
# setup.sh — installs everything this dotfiles repo depends on and symlinks
# configs into place. Safe to re-run any time: existing symlinks are left
# alone, real files in the way are backed up, and `brew install` is a no-op
# for already-installed packages.
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# ------------------------------------------------------------------------------
# Output helpers
# ------------------------------------------------------------------------------
c_blue=$'\033[1;34m'; c_green=$'\033[1;32m'; c_yellow=$'\033[1;33m'; c_reset=$'\033[0m'

step() { printf '\n%s==>%s %s\n' "$c_blue" "$c_reset" "$1"; }
ok()   { printf '  %s✓%s %s\n' "$c_green" "$c_reset" "$1"; }
skip() { printf '  %s-%s %s\n' "$c_yellow" "$c_reset" "$1"; }

# ------------------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------------------
step "Checking for Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "  Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ok "Homebrew installed"
else
  ok "Homebrew already installed"
fi

# ------------------------------------------------------------------------------
# Packages
# ------------------------------------------------------------------------------
# Homebrew's tap-trust gate blocks loading formulae/casks from third-party
# taps until explicitly trusted — and it validates every formula/cask in a
# tap at tap-time, so an *untrusted* tap fails that validation and the whole
# `brew tap` call errors out and rolls back, rather than just refusing the
# one formula later. Trust each tap before tapping it, not after.
step "Trusting third-party Homebrew taps used by this repo"
brew trust --tap FelixKratz/formulae nikitabobko/tap anomalyco/tap can1357/tap stablyai/orca oven-sh/bun >/dev/null
ok "Trusted"

step "Tapping custom Homebrew repositories"
brew tap FelixKratz/formulae
brew tap nikitabobko/tap
brew tap anomalyco/tap
brew tap can1357/tap      # omp — coding agent CLI
brew tap stablyai/orca    # Orca — agent development environment (ADE)
brew tap oven-sh/bun      # bun — JS runtime required by omp's plugin manager (omp/model-profiles below)

step "Installing command-line tools"
FORMULAE=(
  git
  git-delta
  zsh
  neovim
  tree-sitter-cli # required by nvim-treesitter's main branch to compile parsers
  starship
  fzf
  zoxide
  eza
  bat
  ripgrep
  fd
  dust
  btop
  htop
  yazi
  fastfetch
  gh
  lua
  tmux
  wget # required by Mason's clangd installer (Neovim's C/C++ LSP) — no curl fallback
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
  FelixKratz/formulae/borders
  FelixKratz/formulae/sketchybar
  anomalyco/tap/opencode
  can1357/tap/omp # coding agent CLI, used inside Orca's ADE below
  oven-sh/bun/bun # JS runtime `omp plugin install` shells out to
)
for formula in "${FORMULAE[@]}"; do
  if brew list --formula "$formula" &>/dev/null; then
    skip "$formula already installed"
  else
    brew install "$formula"
    ok "$formula installed"
  fi
done

step "Installing apps and fonts (casks)"
CASKS=(
  nikitabobko/tap/aerospace
  wezterm
  font-jetbrains-mono-nerd-font
  font-sketchybar-app-font
  claude-code
  stablyai/orca/orca # ADE — orchestrates omp/Claude Code/etc. across parallel worktrees
  slack
  thebrowsercompany-dia
  zen
  obsidian
  spotify
)
for cask in "${CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    skip "$cask already installed"
  else
    brew install --cask "$cask"
    ok "$cask installed"
  fi
done

# ------------------------------------------------------------------------------
# SbarLua — the Lua API SketchyBar's config uses.
# https://github.com/FelixKratz/SbarLua
# ------------------------------------------------------------------------------
step "Building SbarLua (SketchyBar's Lua API)"
SBARLUA_DIR="$HOME/.local/share/sketchybar_lua"
if [[ -d "$SBARLUA_DIR" ]]; then
  skip "SbarLua already built at $SBARLUA_DIR"
else
  tmp_dir="$(mktemp -d)"
  git clone --depth 1 https://github.com/FelixKratz/SbarLua.git "$tmp_dir"
  (cd "$tmp_dir" && make install)
  rm -rf "$tmp_dir"
  ok "SbarLua built"
fi

# ------------------------------------------------------------------------------
# sketchybar-app-font's icon map — a generated app-name -> ligature table
# (~800 lines), downloaded rather than committed. The font itself is the
# font-sketchybar-app-font cask above; this is just the lookup data.
# https://github.com/kvndrsslr/sketchybar-app-font
# ------------------------------------------------------------------------------
step "Fetching sketchybar-app-font's icon map"
ICON_MAP="$HOME/.local/share/sketchybar/icon_map.lua"
if [[ -f "$ICON_MAP" ]]; then
  skip "icon_map.lua already present at $ICON_MAP"
else
  mkdir -p -- "$(dirname -- "$ICON_MAP")"
  icon_map_url="$(curl -fsSL https://api.github.com/repos/kvndrsslr/sketchybar-app-font/releases/latest \
    | grep '"browser_download_url".*icon_map\.lua"' \
    | sed -E 's/.*"(https:[^"]+)".*/\1/')"
  if [[ -n "$icon_map_url" ]] && curl -fsSL "$icon_map_url" -o "$ICON_MAP"; then
    ok "icon_map.lua fetched"
  else
    echo "  {}" >"$ICON_MAP"
    skip "couldn't fetch icon_map.lua — wrote an empty map, apps just won't show icons per-workspace"
  fi
fi

# ------------------------------------------------------------------------------
# Oh my tmux! — vendored upstream, customized via tmux/tmux.conf.local.
# https://github.com/gpakosz/.tmux
# ------------------------------------------------------------------------------
step "Vendoring Oh my tmux!"
OH_MY_TMUX_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/oh-my-tmux"
if [[ -d "$OH_MY_TMUX_DIR" ]]; then
  skip "Oh my tmux! already vendored at $OH_MY_TMUX_DIR"
else
  mkdir -p -- "$(dirname -- "$OH_MY_TMUX_DIR")"
  git clone --quiet --single-branch https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX_DIR"
  ok "Oh my tmux! vendored"
fi

# ------------------------------------------------------------------------------
# Symlinks
# ------------------------------------------------------------------------------
link() {
  local src="$1" dest="$2"

  mkdir -p -- "$(dirname -- "$dest")"

  if [[ -L "$dest" && "$(readlink -- "$dest")" == "$src" ]]; then
    skip "$dest already linked"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p -- "$BACKUP_DIR"
    mv -- "$dest" "$BACKUP_DIR/"
    echo "  (backed up existing $dest -> $BACKUP_DIR/)"
  fi

  ln -s -- "$src" "$dest"
  ok "linked $dest -> $src"
}

step "Symlinking configs into place"
link "$DOTFILES_DIR/.zshrc"          "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh"             "$HOME/.config/zsh"
link "$DOTFILES_DIR/aerospace"       "$HOME/.config/aerospace"
link "$DOTFILES_DIR/borders"         "$HOME/.config/borders"
link "$DOTFILES_DIR/sketchybar"      "$HOME/.config/sketchybar"
link "$DOTFILES_DIR/wezterm"         "$HOME/.config/wezterm"
link "$DOTFILES_DIR/nvim"            "$HOME/.config/nvim"
link "$DOTFILES_DIR/fastfetch"       "$HOME/.config/fastfetch"
link "$DOTFILES_DIR/yazi"            "$HOME/.config/yazi"
link "$DOTFILES_DIR/k9s/config.yaml"  "$HOME/.config/k9s/config.yaml"
link "$DOTFILES_DIR/k9s/skins"        "$HOME/.config/k9s/skins"
link "$DOTFILES_DIR/k9s/plugins.yaml" "$HOME/.config/k9s/plugins.yaml"
link "$DOTFILES_DIR/btop/btop.conf"  "$HOME/.config/btop/btop.conf"
link "$DOTFILES_DIR/btop/themes"     "$HOME/.config/btop/themes"
link "$DOTFILES_DIR/opencode/tui.json"      "$HOME/.config/opencode/tui.json"
link "$DOTFILES_DIR/opencode/themes"        "$HOME/.config/opencode/themes"
link "$DOTFILES_DIR/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
# omp reads its settings from ~/.omp/agent/config.yml, not the XDG config dir
# (that path is legacy, not $XDG_CONFIG_HOME-based, unless `omp config
# init-xdg` has been run — this repo hasn't opted into that).
link "$DOTFILES_DIR/omp/config.yml" "$HOME/.omp/agent/config.yml"
# models.yml defines the custom "cekat" provider (office LiteLLM gateway),
# same $CEKAT_API_KEY as opencode's provider — see zsh/.zshrc.local.example.
link "$DOTFILES_DIR/omp/models.yml" "$HOME/.omp/agent/models.yml"
# model-profiles/*.yml are switched between at runtime with `/profile <name>`
# (omp-model-profiles plugin, installed below) — kept in this repo so both
# profiles are versioned next to the models.yml provider they reference.
link "$DOTFILES_DIR/omp/model-profiles" "$HOME/.omp/model-profiles"
link "$DOTFILES_DIR/starship.toml"   "$HOME/.config/starship.toml"
link "$OH_MY_TMUX_DIR/.tmux.conf"    "$HOME/.config/tmux/tmux.conf"
link "$DOTFILES_DIR/tmux/tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
# Also symlink the legacy ~/.tmux.conf path — same source files, so the two
# locations can never drift. oh-my-tmux checks ~/.tmux.conf first, so this
# one takes precedence when present; harmless either way.
link "$OH_MY_TMUX_DIR/.tmux.conf"    "$HOME/.tmux.conf"
link "$DOTFILES_DIR/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
link "$DOTFILES_DIR/git/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES_DIR/git/.gitconfig-personal" "$HOME/.gitconfig-personal"
link "$DOTFILES_DIR/git/.gitconfig-work"     "$HOME/.gitconfig-work"

# ------------------------------------------------------------------------------
# omp-model-profiles — https://github.com/rezhajulio/omp-model-profiles
# `/profile personal-labs` / `/profile work-cekataiofficial` switch modelRoles
# in-session (see omp/model-profiles/). Installed via omp's own npm-backed
# plugin manager, which shells out to bun (tapped/installed above).
# ------------------------------------------------------------------------------
step "Installing omp-model-profiles plugin"
if omp plugin list 2>/dev/null | grep -q 'omp-model-profiles'; then
  skip "omp-model-profiles already installed"
else
  omp plugin install github:rezhajulio/omp-model-profiles
  ok "omp-model-profiles installed"
fi

step "Setting up personal/work workspace directories"
mkdir -p "$HOME/Artifacts/labs" "$HOME/Artifacts/work"
ok "~/Artifacts/labs (personal) and ~/Artifacts/work (work) ready"

step "Setting up machine-local overrides"
if [[ -f "$HOME/.zshrc.local" ]]; then
  skip "~/.zshrc.local already exists"
else
  cp -- "$DOTFILES_DIR/zsh/.zshrc.local.example" "$HOME/.zshrc.local"
  ok "created ~/.zshrc.local from the example (git-ignored, yours to edit)"
fi

# ------------------------------------------------------------------------------
# Hide the native macOS menu bar so SketchyBar is the only bar on screen.
# No SIP involved — this is a standard, reversible `defaults` key (flip it
# back with `defaults write NSGlobalDomain _HIHideMenuBar -bool false`).
# ------------------------------------------------------------------------------
step "Hiding the native macOS menu bar"
if [[ "$(defaults read NSGlobalDomain _HIHideMenuBar 2>/dev/null)" == "1" ]]; then
  skip "native menu bar already hidden"
else
  defaults write NSGlobalDomain _HIHideMenuBar -bool true
  killall SystemUIServer >/dev/null 2>&1 || true
  ok "native menu bar hidden (log out/in if it's still visible)"
fi

# ------------------------------------------------------------------------------
# Start background services
# ------------------------------------------------------------------------------
step "Starting services"
brew services restart borders >/dev/null
ok "borders running"

brew services restart sketchybar >/dev/null
ok "sketchybar running"

if [[ -d "/Applications/AeroSpace.app" ]]; then
  open -g -a AeroSpace
  ok "AeroSpace launched (configured to start at login from here on)"
fi

# ------------------------------------------------------------------------------
step "Done"
echo "  Restart your terminal (or open WezTerm) to pick up the new shell config."
echo "  AeroSpace/SketchyBar/Borders are running now and will start at login."
if [[ "$SHELL" != *"/zsh" ]] || [[ "$(command -v zsh)" != "$(brew --prefix)/bin/zsh" ]]; then
  echo "  Homebrew's zsh is installed but not your login shell. To switch:"
  echo "    echo \"\$(brew --prefix)/bin/zsh\" | sudo tee -a /etc/shells"
  echo "    chsh -s \"\$(brew --prefix)/bin/zsh\""
fi
if [[ -d "$BACKUP_DIR" ]]; then
  echo "  Anything replaced during setup was backed up to: $BACKUP_DIR"
fi
