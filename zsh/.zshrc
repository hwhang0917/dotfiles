# ============ Utility ==============
function log() {
    local GREEN='\033[32m'
    local YELLOW='\033[33m'
    local RED='\033[31m'
    local BLUE='\033[34m'
    local GRAY='\033[2m'
    local RESET='\033[0m'

    local msg_type="$1"
    local msg="$2"
    local comment="$3"

    case "$msg_type" in
        "INFO")
            echo -e "${GREEN}[INFO]${RESET} $msg" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${RESET} $msg" >&2
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${RESET} $msg" >&2
            ;;
        *)
            echo -e "${BLUE}[DEBUG]${RESET} $msg" >&2
            ;;
    esac

    if [ -n "$comment" ]; then
        echo -e "${GRAY}  $comment${RESET}" >&2
    fi
}
# ===================================

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

# Terminal colors
if [[ -n "$TMUX" ]]; then
    export TERM=screen-256color
else
    export TERM=xterm-256color
fi

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
source "$ZSH_PLUGIN_DIR/ohmyzsh/plugins/git/git.plugin.zsh"
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
if command -v claudelytics >/dev/null 2>&1; then
    alias ca="claudelytics"
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
() {
    [[ "$MANUAL_INIT" == "true" ]] || return

    local has_docker=false has_systemctl=false
    command -v docker >/dev/null 2>&1 && has_docker=true
    command -v systemctl >/dev/null 2>&1 && has_systemctl=true

    local ezflow_present=false eztalk_present=false eml_present=false

    if $has_docker; then
        docker ps -a --filter 'name=ezflow_mock-ezflow-mock-1' --format '{{.Names}}' 2>/dev/null | grep -q '^ezflow_mock-ezflow-mock-1$' && ezflow_present=true
        docker ps -a --filter 'name=eztalk30_database-mariadb-1' --format '{{.Names}}' 2>/dev/null | grep -q '^eztalk30_database-mariadb-1$' && eztalk_present=true
    fi

    if $has_systemctl; then
        systemctl --user cat local-eml >/dev/null 2>&1 && eml_present=true
    fi

    # Short-circuit if docker/systemd missing or the containers/service don't exist
    if ! $ezflow_present && ! $eztalk_present && ! $eml_present; then
        return
    fi

    local ezflow_ok=true eztalk_ok=true eml_ok=true

    if $ezflow_present; then
        docker ps --filter 'name=ezflow_mock-ezflow-mock-1' --filter 'status=running' -q 2>/dev/null | grep -q . || ezflow_ok=false
    fi
    if $eztalk_present; then
        docker ps --filter 'name=eztalk30_database-mariadb-1' --filter 'status=running' -q 2>/dev/null | grep -q . || eztalk_ok=false
    fi
    if $eml_present; then
        systemctl --user is-active --quiet local-eml 2>/dev/null || eml_ok=false
    fi

    # Short-circuit if all present targets are already running
    [[ $ezflow_ok == true && $eztalk_ok == true && $eml_ok == true ]] && return

    if [[ $ezflow_present == true && $ezflow_ok == false ]]; then
        log "INFO" "Starting docker compose: ezflow_mock"
        (cd "$HOME/kaoni/ezflow_mock" && docker compose up -d >/dev/null 2>&1) &!
    fi
    if [[ $eztalk_present == true && $eztalk_ok == false ]]; then
        log "INFO" "Starting docker compose: eztalk3.0_database"
        (cd "$HOME/kaoni/eztalk3.0_database" && docker compose --profile mariadb up -d >/dev/null 2>&1) &!
    fi
    if [[ $eml_present == true && $eml_ok == false ]]; then
        log "INFO" "Starting systemd user service: local-eml"
        systemctl --user enable --now local-eml >/dev/null 2>&1
    fi
}
# ===================================
