# ==============================================================================
# .zshrc — interactive shell configuration.
#
# Structure (in order): environment -> history -> options -> completion ->
# keybindings -> plugins -> prompt -> aliases & functions.
#
# Machine-specific config lives in ~/.zshrc.local (git-ignored) and is
# sourced last, so it always wins.
# ==============================================================================

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export ZSH_CONFIG_DIR="$XDG_CONFIG_HOME/zsh"

export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"

# Homebrew (Apple Silicon default prefix; no-op if already on PATH).
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------
HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY       # record timestamps
setopt HIST_EXPIRE_DUPS_FIRST # trim dupes first when HISTFILE fills
setopt HIST_IGNORE_DUPS       # don't record a line already the previous one
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate lines
setopt HIST_IGNORE_SPACE      # lines starting with space aren't recorded
setopt HIST_VERIFY            # expand history refs before running
setopt SHARE_HISTORY          # share history across sessions
setopt INC_APPEND_HISTORY     # write as commands run, not at shell exit

# ------------------------------------------------------------------------------
# Options
# ------------------------------------------------------------------------------
setopt AUTO_CD              # `foo` instead of `cd foo`
setopt AUTO_PUSHD           # cd pushes onto the directory stack
setopt PUSHD_IGNORE_DUPS
setopt CORRECT              # suggest a fix for a mistyped command
setopt INTERACTIVE_COMMENTS # allow `#` comments in the interactive shell
setopt NO_BEEP

# ------------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------------
autoload -Uz compinit
zmodload zsh/complist

typeset -g ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"
mkdir -p "$(dirname "$ZSH_COMPDUMP")"
compinit -d "$ZSH_COMPDUMP"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'

# ------------------------------------------------------------------------------
# Keybindings
# ------------------------------------------------------------------------------
bindkey -e # emacs-style keybindings

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[1;5C' forward-word    # ctrl-right
bindkey '^[[1;5D' backward-word   # ctrl-left
bindkey '^[[3~'   delete-char     # fn-delete / forward-delete

# ------------------------------------------------------------------------------
# Plugins (installed via Homebrew; each guarded so a missing plugin never
# breaks shell startup)
# ------------------------------------------------------------------------------
_zsh_plugin_dir="${HOMEBREW_PREFIX:-/opt/homebrew}/share"

[[ -f "$_zsh_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "$_zsh_plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -f "$_zsh_plugin_dir/zsh-history-substring-search/zsh-history-substring-search.zsh" ]] &&
  source "$_zsh_plugin_dir/zsh-history-substring-search/zsh-history-substring-search.zsh"

# Syntax highlighting must be sourced last among plugins.
[[ -f "$_zsh_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
  source "$_zsh_plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset _zsh_plugin_dir

# fzf: fuzzy history/file search (Ctrl-R, Ctrl-T, Alt-C)
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# zoxide: a smarter `cd` that ranks directories by frecency
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

# gvm: Go version manager (https://gvm.sh), installed by development-tools.sh
if command -v gvm >/dev/null 2>&1; then
  eval "$(gvm env)"
fi

# ------------------------------------------------------------------------------
# Prompt
# ------------------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ------------------------------------------------------------------------------
# Aliases & functions
# ------------------------------------------------------------------------------
for _rc in "$ZSH_CONFIG_DIR"/aliases.zsh "$ZSH_CONFIG_DIR"/functions.zsh; do
  [[ -f "$_rc" ]] && source "$_rc"
done
unset _rc

# Completions must load after compinit above.
[[ -f "$ZSH_CONFIG_DIR/completions.zsh" ]] && source "$ZSH_CONFIG_DIR/completions.zsh"

# Machine-specific overrides — always last.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ------------------------------------------------------------------------------
# Greeting — system info on new top-level shells only (skipped inside tmux
# panes/windows so it doesn't repeat every time you split).
# ------------------------------------------------------------------------------
if [[ -o interactive && -z "$TMUX" ]] && command -v fastfetch >/dev/null 2>&1; then
  fastfetch
fi
