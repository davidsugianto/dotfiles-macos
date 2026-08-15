#!/usr/bin/env bash
# ==============================================================================
# development-tools.sh — optional DevOps toolchain, layered on top of the
# base install in setup.sh (run that first). Kept as a separate script
# because not everyone using this repo needs a Kubernetes IDE and three
# different IaC tools — opt in explicitly by running this one too.
#
# Safe to re-run: everything here is idempotent, same as setup.sh.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Output helpers (same style as setup.sh)
# ------------------------------------------------------------------------------
c_blue=$'\033[1;34m'; c_green=$'\033[1;32m'; c_yellow=$'\033[1;33m'; c_reset=$'\033[0m'

step() { printf '\n%s==>%s %s\n' "$c_blue" "$c_reset" "$1"; }
ok()   { printf '  %s✓%s %s\n' "$c_green" "$c_reset" "$1"; }
skip() { printf '  %s-%s %s\n' "$c_yellow" "$c_reset" "$1"; }

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found — run ./setup.sh first." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# CLI tools
# ------------------------------------------------------------------------------
step "Installing DevOps CLI tools"
FORMULAE=(
  kubernetes-cli   # kubectl
  kubectx          # also installs kubens
  lazygit
  jq
  yq
  opentofu         # tofu — Terraform-compatible, open source
  terragrunt
  ansible          # ansible-vault ships as a subcommand, not a separate package
  awscli           # this formula is AWS CLI v2
  python
  node             # npm ships with node
  pnpm
)
for formula in "${FORMULAE[@]}"; do
  if brew list --formula "$formula" &>/dev/null; then
    skip "$formula already installed"
  else
    brew install "$formula"
    ok "$formula installed"
  fi
done

# ------------------------------------------------------------------------------
# GUI apps
# ------------------------------------------------------------------------------
step "Installing GUI apps (casks)"
CASKS=(
  visual-studio-code
  gcloud-cli   # gcloud, gsutil, bq
  freelens     # open-source Lens fork — Kubernetes IDE
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
# gvm — Go version manager. https://gvm.sh
# Installed via its own installer rather than Homebrew (no formula for it);
# GVM_NO_MODIFY=1 stops the installer from editing ~/.zshrc itself — the
# shell hook is already wired in .zshrc (`eval "$(gvm env)"`), guarded so
# it's a no-op until gvm is actually installed.
# ------------------------------------------------------------------------------
step "Installing gvm (Go version manager)"
if [[ -x "$HOME/bin/gvm" ]]; then
  skip "gvm already installed at $HOME/bin/gvm"
else
  echo "  Installing from gvm.run/install.sh — this pipes a remote script to"
  echo "  bash. Review it yourself first if you'd rather not take that on faith:"
  echo "  https://gitlab.com/devnw/go/gvm/-/raw/main/install.sh"
  GVM_NO_MODIFY=1 bash -c "$(curl -fsSL gvm.run/install.sh)"
  ok "gvm installed"
fi

# ------------------------------------------------------------------------------
step "Done"
echo "  New shell tools are on PATH now; open a new terminal to pick them up."
echo "  Get Go itself with:  gvm install latest && gvm tools init"
echo "  kubectl/yq/aws/tofu completions are wired in zsh/completions.zsh."
