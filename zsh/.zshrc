# ============== Init ===============
source $HOME/.zplug/init.zsh
# ===================================

# ============ Settings =============
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
export TERM=xterm-256color
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
alias docker="podman"
alias p-clean="sudo paccache -r && sudo pacman -Sc && sudo yay -Sc"
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

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
# ===================================

