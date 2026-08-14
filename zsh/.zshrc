# ============== Init ===============
ZSH_PLUGIN_DIR="$HOME/.zsh-plugins"

autoload -Uz compinit
zmodload zsh/stat zsh/datetime
local zcompdump="$HOME/.zcompdump"
if [[ -f "$zcompdump" ]] && (( EPOCHSECONDS - $(zstat +mtime "$zcompdump") < 86400 )); then
    compinit -C -d "$zcompdump"
else
    compinit -d "$zcompdump"
fi
bindkey -e

# Enable Edit command via EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
# ===================================

# ============ Security =============
umask 022

# Point gpg-agent's pinentry at this terminal (no-op without a tty)
[[ -t 0 ]] && export GPG_TTY=$(tty)

# Dependency Cooldowns
export UV_EXCLUDE_NEWER="3 days"
export PIP_UPLOADED_PRIOR_TO="P3D"
export COOLDOWN_MINUTES=4320
# ===================================

# ============ Settings =============
# History settings
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Editor preference
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim"
else
    export EDITOR="vi"
fi

# Podman settings
export PODMAN_COMPOSE_WARNING_LOGS=false

# Manual init
MANUAL_INIT=${MANUAL_INIT:-true}
# ===================================

# ============= Plugins =============
# Managed as git submodules in zsh/.zsh-plugins/
source "$HOME/.config/zsh/git-aliases.zsh"  # vendored ohmyzsh git plugin
source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"  # loaded last
# ===================================

# ============= Aliases =============
# Common aliases
alias ..="cd .."
alias ...="cd ../.."

# OS-Specific aliases
case "$OSTYPE" in
    linux*)
        if [[ -f /etc/arch-release ]]; then
            alias p="sudo pacman"
            if command -v paru >/dev/null 2>&1; then
                alias p-clean='sudo paccache -r; sudo pacman -Sc; paru -Sc'
            else
                alias p-clean='sudo paccache -r; sudo pacman -Sc'
            fi
        fi
        ;;
esac

# Editor aliases
if command -v nvim >/dev/null 2>&1; then
    alias vim="nvim"
fi
if command -v vim >/dev/null 2>&1; then
    alias vi="command vim"
fi

# Claude Code aliases
if command -v claude >/dev/null 2>&1; then
    alias c="claude"
    alias cc="claude -c"
    alias cr="claude -r"
fi
if command -v npx >/dev/null 2>&1; then
    alias ca="npx ccusage@latest"
fi

# GNU tool modern replacements
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --icons --git"
elif command -v exa >/dev/null 2>&1; then
    alias ls="exa --icons --git"
else
    alias ls="ls --color=auto"
fi
alias l="ls -lah"
alias ll="ls -lh"
alias la="ls -lAh"

if command -v bat >/dev/null 2>&1; then
    alias cat="bat"
fi

# Deprecation aliases
alias sxiv="nsxiv"
# ===================================

# ========== PATH & eval ============
source "$HOME/.config/zsh/path.zsh"
source "$HOME/.config/zsh/eval.zsh"
# ===================================

# ========= Manual Services =========
[[ "$MANUAL_INIT" == "true" && -f "$HOME/.config/zsh/manual-init.zsh" ]] && source "$HOME/.config/zsh/manual-init.zsh"
# ===================================

# =========== Local Envs ============
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# ===================================

# ============== Conda ==============
# Portable conda init: first existing base among common install locations.
# Override with CONDA_ROOT in ~/.zshrc.local for non-standard paths.
for _conda_base in "$CONDA_ROOT" "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/miniforge3" "/opt/miniconda3" "/opt/conda"; do
    [[ -x "$_conda_base/bin/conda" ]] || continue
    __conda_setup="$("$_conda_base/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    elif [ -f "$_conda_base/etc/profile.d/conda.sh" ]; then
        . "$_conda_base/etc/profile.d/conda.sh"
    else
        export PATH="$_conda_base/bin:$PATH"
    fi
    unset __conda_setup
    break
done
unset _conda_base
# ===================================
