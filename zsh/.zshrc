# Zplug
source $HOME/.zplug/init.zsh

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

# Custom aliases
alias p="sudo pacman"
alias vi="nvim"
alias vim="nvim"
alias l="ls -lah"
alias ls="eza --icons --git"
alias cat="bat"
alias sxiv="nsxiv"
alias docker="podman"

# fnm
FNM_PATH="/home/hswhang/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/hswhang/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

# Starship
eval "$(starship init zsh)"

. "$HOME/.local/bin/env"

# bun completions
[ -s "/home/hswhang/.bun/_bun" ] && source "/home/hswhang/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Zoxide
eval "$(zoxide init zsh)"

# GH CLI
eval "$(gh copilot alias -- zsh)"
