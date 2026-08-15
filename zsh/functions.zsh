#!/usr/bin/env zsh
# ==============================================================================
# functions.zsh — reusable shell functions
# ==============================================================================

# Make a directory and cd into it in one step.
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# Extract almost any archive format without remembering the right flags.
extract() {
  if [[ ! -f "$1" ]]; then
    echo "extract: '$1' is not a valid file" >&2
    return 1
  fi
  case "$1" in
    *.tar.bz2)  tar xjf "$1"   ;;
    *.tar.gz)   tar xzf "$1"   ;;
    *.tar.xz)   tar xJf "$1"   ;;
    *.tar)      tar xf "$1"    ;;
    *.tbz2)     tar xjf "$1"   ;;
    *.tgz)      tar xzf "$1"   ;;
    *.bz2)      bunzip2 "$1"   ;;
    *.gz)       gunzip "$1"    ;;
    *.zip)      unzip "$1"     ;;
    *.rar)      unrar x "$1"   ;;
    *.7z)       7z x "$1"      ;;
    *)          echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
  esac
}

# Fuzzy-find and kill a process (requires fzf).
fkill() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fkill: fzf is not installed" >&2
    return 1
  fi
  local pid
  pid=$(ps -ax -o pid,comm | sed 1d | fzf | awk '{print $1}')
  [[ -n "$pid" ]] && kill -"${1:-9}" "$pid"
}

# Fuzzy-find and check out a local git branch (requires fzf).
fbr() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fbr: fzf is not installed" >&2
    return 1
  fi
  local branch
  branch=$(git branch --format='%(refname:short)' | fzf) && git checkout "$branch"
}

# Quick weather check.
weather() {
  curl -s "wttr.in/${1:-}"
}

# Serve the current directory over HTTP.
serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

# yazi: `y` opens the file manager, and cds the shell to wherever you
# navigated to on quit (press q). Official wrapper, see
# https://yazi-rs.github.io/docs/quick-start#shell-wrapper
if command -v yazi >/dev/null 2>&1; then
  y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
  }
fi
