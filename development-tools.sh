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
  k9s
  lazygit
  jq
  yq
  opentofu         # tofu — Terraform-compatible, open source
  terragrunt
  ansible          # ansible-vault ships as a subcommand, not a separate package
  awscli           # this formula is AWS CLI v2
  colima           # container runtime (Docker Desktop alternative), needs the docker CLI below
  docker           # CLI only — no daemon; colima provides that
  docker-compose
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
# docker-compose ships as a CLI plugin, and the plain `docker` CLI only
# looks in a couple of hardcoded locations for plugins — Homebrew's isn't
# one of them, so `docker compose` fails to resolve until this is set.
# ------------------------------------------------------------------------------
step "Pointing the docker CLI at Homebrew's compose plugin"
DOCKER_CONFIG="$HOME/.docker/config.json"
mkdir -p -- "$(dirname -- "$DOCKER_CONFIG")"
[[ -f "$DOCKER_CONFIG" ]] || echo '{}' >"$DOCKER_CONFIG"
if jq -e '(.cliPluginsExtraDirs // []) | index("/opt/homebrew/lib/docker/cli-plugins")' \
  "$DOCKER_CONFIG" >/dev/null 2>&1; then
  skip "docker CLI already configured for the compose plugin"
else
  tmp_config="$(mktemp)"
  jq '.cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + ["/opt/homebrew/lib/docker/cli-plugins"] | unique)' \
    "$DOCKER_CONFIG" >"$tmp_config" && mv "$tmp_config" "$DOCKER_CONFIG"
  ok "docker CLI configured — 'docker compose' resolves now"
fi

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
# gke-gcloud-auth-plugin — kubectl needs this to authenticate against GKE
# clusters; client-go dropped its built-in GCP auth provider, so GKE now
# requires this plugin (gcloud SDK 363.0.0+ / GKE 1.26+).
# ------------------------------------------------------------------------------
step "Installing gke-gcloud-auth-plugin"
if command -v gke-gcloud-auth-plugin >/dev/null 2>&1; then
  skip "gke-gcloud-auth-plugin already installed"
else
  gcloud components install gke-gcloud-auth-plugin --quiet
  ok "gke-gcloud-auth-plugin installed"
fi

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
echo "  Colima doesn't autostart — run 'colima start' to bring up the docker daemon."
echo "  'gcloud auth login' + 'gcloud container clusters get-credentials' set up kubectl for GKE."
