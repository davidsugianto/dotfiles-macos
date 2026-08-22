#!/usr/bin/env zsh
# ==============================================================================
# aliases.zsh — shorthand commands, guarded so a missing tool never breaks
#               an interactive shell.
# ==============================================================================

# ------------------------------------------------------------------------------
# Modern CLI replacements
# ------------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first'
  alias la='eza -lah --icons --group-directories-first'
  alias lt='eza --tree --icons --level=2 --group-directories-first'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never --style=plain'
  alias catn='bat --paging=never'          # cat with line numbers / syntax
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

if command -v fd >/dev/null 2>&1; then
  alias find='fd'
fi

if command -v dust >/dev/null 2>&1; then
  alias du='dust'
fi

if command -v btop >/dev/null 2>&1; then
  alias top='btop'
fi

if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

if command -v yazi >/dev/null 2>&1; then
  alias fm='yazi' # `y` is the cd-on-quit wrapper below, in functions.zsh
fi

# ------------------------------------------------------------------------------
# Safety nets — confirm before anything destructive
# ------------------------------------------------------------------------------
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# ------------------------------------------------------------------------------
# Navigation
# ------------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'          # jump to previous directory

# ------------------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  alias brewup='brew update && brew upgrade && brew cleanup'
  alias brewls='brew list --formula && echo "---" && brew list --cask'
fi

# ------------------------------------------------------------------------------
# git
# ------------------------------------------------------------------------------
alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch --all --prune'
alias gl='git log --oneline --graph --decorate -20'
alias gll='git log --graph --pretty=format:"%C(yellow)%h%Creset %C(blue)%an%Creset %C(green)(%ar)%Creset%n  %s%n"'
alias gst='git stash'
alias gstp='git stash pop'
alias gr='git restore'
alias grs='git restore --staged'

# ------------------------------------------------------------------------------
# kubectl
# ------------------------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  alias k='kubectl'
  alias kg='kubectl get'
  alias kgp='kubectl get pods'
  alias kgpw='kubectl get pods -o wide'
  alias kgs='kubectl get svc'
  alias kgd='kubectl get deployments'
  alias kga='kubectl get all'
  alias kgn='kubectl get nodes'
  alias kgns='kubectl get namespaces'
  alias kd='kubectl describe'
  alias kdp='kubectl describe pod'
  alias kds='kubectl describe svc'
  alias kdd='kubectl describe deployment'
  alias kl='kubectl logs'
  alias klf='kubectl logs -f'
  alias ke='kubectl exec -it'
  alias kaf='kubectl apply -f'
  alias kdf='kubectl delete -f'
  alias kdel='kubectl delete'
  alias krr='kubectl rollout restart'
  alias krs='kubectl rollout status'
  alias kgc='kubectl config get-contexts'
  alias kuc='kubectl config use-context'
fi

if command -v kubectx >/dev/null 2>&1; then
  alias kctx='kubectx'
fi

if command -v kubens >/dev/null 2>&1; then
  alias kns='kubens'
fi

# ------------------------------------------------------------------------------
# Aerospace / Borders / SketchyBar — reload the window-management stack
# ------------------------------------------------------------------------------
if command -v aerospace >/dev/null 2>&1; then
  alias asr='aerospace reload-config'
fi

if command -v sketchybar >/dev/null 2>&1; then
  alias sbr='sketchybar --reload'
fi

if command -v borders >/dev/null 2>&1; then
  alias bdr='brew services restart borders'
fi

if command -v tmux >/dev/null 2>&1; then
  alias tmr='tmux source-file "$HOME/.config/tmux/tmux.conf"'
  alias ta='tmux attach'
fi

# ------------------------------------------------------------------------------
# Misc
# ------------------------------------------------------------------------------
alias reload='exec zsh'
alias path='echo -e ${PATH//:/\\n}'
