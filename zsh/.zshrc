# ============== Init ===============
source $HOME/.zplug/init.zsh
bindkey -e
# ===================================

# ============ Security =============
umask 022
# ===================================

# ============ Settings =============
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

if [[ -n "$TMUX" ]]; then
    export TERM=screen-256color
else
    export TERM=xterm-256color
fi

export EDITOR="nvim"
export PODMAN_COMPOSE_WARNING_LOGS=false
# ===================================

# ============= Plugins =============
zplug "plugins/git", from:oh-my-zsh
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-syntax-highlighting", defer:2

# Install plugins if there are plugins that have not been installed
if ! zplug check; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load
# ===================================

# ============= Aliases =============
alias p="sudo pacman"
alias vi="nvim"
alias vim="nvim"
alias l="ls -lah"
alias ls="eza --icons --git"
alias ll="ls -lh"
alias la="ls -lAh"
alias cat="bat"
alias sxiv="nsxiv"
alias p-clean="sudo paccache -r && sudo pacman -Sc && sudo yay -Sc"
# ===================================

# ============ Hacking  ============
# This section is for some wacky hacking that will make your life easier.

# NetworkManager TUI is hard to read in catppuccin theme, so we change the colors.
alias nmtui='NEWT_COLORS="root=white,black;window=white,black;border=yellow,black;listbox=white,black;label=white,black;checkbox=white,black;compactbutton=white,black;textbox=yellow,black;entry=yellow,black;editline=yellow,black" nmtui'
# SSH connection helper with search filter support
function fssh() {
    local host
    local search_term=""

    # If arguments provided, use as search filter
    if [[ $# -gt 0 ]]; then
        search_term="$1"
    fi

    # Get hosts and run fzf with optional search term
    host=$(grep "^Host " ~/.ssh/config | grep -v "\*" | cut -d" " -f2- | fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt="SSH > " \
        --query="$search_term" \
        --preview="grep -A 4 'Host {}' ~/.ssh/config")

    if [[ -n $host ]]; then
        echo "Connecting to $host..."
        ssh "$host"
    fi
}
# Zoxide + Tmux
function zt() {
    if [ -z "$TMUX" ]; then
        echo -e "\033[0;31mERROR: not in a tmux session.\033[0m"
        return 1
    fi
    \builtin local result
    if [ -z "$1" ]; then
        result=$(zoxide query --interactive)
    else
        result=$(zoxide query --interactive "$1")
    fi
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31mERROR: zoxide query failed.\033[0m"
        return 1
    fi
    window_name=$(basename "$result")
    tmux new-window -n "$window_name" -c "$result"
}
# ===================================

# ========== PATH & eval ============
# Constants
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SCRIPT="$HOME/.local/scripts"
mkdir -p "$LOCAL_BIN" "$LOCAL_SCRIPT"

# Extend PATH
export PATH="$LOCAL_BIN:$LOCAL_SCRIPT:$PATH"

# Golang Binary
if command -v go >/dev/null 2>&1; then
    GOBIN="$(go env GOPATH)/bin"
    export PATH="$GOBIN:$PATH"
fi

# Go Version Manager (govm)
if command -v govm >/dev/null 2>&1; then
    export PATH="$HOME/.govm/shim:$PATH"
fi

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --use-on-cd)"
fi

# Starship
eval "$(starship init zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Zoxide
eval "$(zoxide init zsh)"

# GH CLI
eval "$(gh copilot alias -- zsh)"

# Humanlog
export PATH="$HOME/.humanlog/bin:$PATH"

# Ruby Gem
export PATH="$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
# ===================================
