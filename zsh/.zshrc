# ============== Init ===============
source $HOME/.zplug/init.zsh
# ===================================
#
# ============ Settings =============
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
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
alias cat="bat"
alias sxiv="nsxiv"
alias docker="podman"
# ===================================

# ========== PATH & eval ============
# Constants
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SCRIPT="$HOME/.local/scripts"

# Extend PATH
export PATH="$LOCAL_BIN:$LOCAL_SCRIPT:$PATH"

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "`fnm env`"
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

