#!/usr/bin/env zsh
# ==============================================================================
# completions.zsh — cached completion scripts for CLI tools.
#
# Each tool's completion script is generated once and written to
# $ZSH_COMPLETION_CACHE/_<tool>. It is only regenerated when the tool's
# binary is newer than the cached file, so shell startup stays fast.
#
# This file is sourced from .zshrc AFTER `compinit` has already run.
# ==============================================================================

typeset -g ZSH_COMPLETION_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$ZSH_COMPLETION_CACHE"

# Map of tool -> command that prints its zsh completion script to stdout.
# Add new tools here as you adopt them. This only covers tools that emit a
# full `#compdef` function — terraform/tofu/aws use a different mechanism
# (see the "complete -C" block below) and don't belong in this map.
typeset -gA _completion_generators=(
  gh        "gh completion -s zsh"
  docker    "docker completion zsh"
  kubectl   "kubectl completion zsh"
  op        "op completion zsh"
  starship  "starship completions zsh"
  yq        "yq completion zsh"
)

_generate_completion_if_stale() {
  local tool="$1" generator="$2"
  local bin cache_file

  bin="$(command -v "$tool" 2>/dev/null)" || return 0
  cache_file="$ZSH_COMPLETION_CACHE/_$tool"

  if [[ ! -f "$cache_file" || "$bin" -nt "$cache_file" ]]; then
    eval "$generator" >| "$cache_file" 2>/dev/null
  fi
}

local tool generator
for tool generator in "${(@kv)_completion_generators}"; do
  _generate_completion_if_stale "$tool" "$generator"
done
unset tool generator

fpath=("$ZSH_COMPLETION_CACHE" $fpath)

# Register the completions generated above. NOTE: this deliberately does NOT
# call `compinit -C` again — `compinit` was already run once in .zshrc, and a
# second call (even with -C) re-sources the on-disk completion dump wholesale
# and silently drops entries for tools that weren't in that dump when it was
# last written (kubectl and docker were observed disappearing this way).
# Each generated script embeds its own `compdef _<tool> <tool>` call, so
# sourcing it directly registers it in $_comps without touching the dump.
local f
for f in "$ZSH_COMPLETION_CACHE"/_*(N); do
  source "$f"
done
unset f

# Extend generated completions to short aliases (see zsh/aliases.zsh).
command -v kubectl >/dev/null 2>&1 && compdef k=kubectl

# ------------------------------------------------------------------------------
# "complete -C" style completions — terraform/tofu and awscli generate their
# completions by shelling back out to the binary on every TAB press rather
# than emitting a static #compdef script, so they can't go through the
# generator map/cache above. bashcompinit provides the `complete` builtin
# these rely on.
# ------------------------------------------------------------------------------
if command -v tofu >/dev/null 2>&1 || command -v terraform >/dev/null 2>&1 || command -v aws_completer >/dev/null 2>&1; then
  autoload -Uz bashcompinit && bashcompinit
fi

command -v tofu >/dev/null 2>&1 && complete -o nospace -C "$(command -v tofu)" tofu
command -v terraform >/dev/null 2>&1 && complete -o nospace -C "$(command -v terraform)" terraform
command -v aws_completer >/dev/null 2>&1 && complete -C "$(command -v aws_completer)" aws
