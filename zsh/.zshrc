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
ZSH_PLUGIN_DIR="$HOME/.zsh"
mkdir -p "$ZSH_PLUGIN_DIR"

if ! command -v git >/dev/null 2>&1; then
    log "ERROR" "git is not installed. Zsh plugins will not be available."
elif ! command -v fd >/dev/null 2>&1; then
    log "ERROR" "fd is not installed. Zsh plugins will not be available." "https://github.com/sharkdp/fd"
else
    function zsh_plugin_load() {
        local repo="$1"
        local source_path="$2"
        local plugin_name="${repo##*/}"
        local plugin_dir="$ZSH_PLUGIN_DIR/$plugin_name"

        if [[ ! -d "$plugin_dir" ]]; then
            log "INFO" "Installing $repo..."
            git clone --depth 1 "https://github.com/$repo.git" "$plugin_dir" 2>/dev/null || {
                log "ERROR" "Failed to clone $repo"
                return 1
            }
        fi

        local init_file
        if [[ -n "$source_path" ]]; then
            init_file="$plugin_dir/$source_path"
        else
            init_file=$(fd -t f -e zsh -d 1 . "$plugin_dir" | head -1)
        fi

        if [[ -z "$init_file" || ! -f "$init_file" ]]; then
            log "WARN" "No sourceable .zsh file found in $plugin_dir"
            return 1
        fi

        source "$init_file"
    }

    function zsh_plugin_update() {
        local plugin_dir
        for plugin_dir in "$ZSH_PLUGIN_DIR"/*/; do
            [[ -d "$plugin_dir/.git" ]] || continue
            log "INFO" "Updating $(basename "$plugin_dir")..."
            git -C "$plugin_dir" pull --ff-only 2>/dev/null || log "WARN" "Failed to update $(basename "$plugin_dir")"
        done
    }
fi

autoload -Uz compinit
zmodload zsh/stat zsh/datetime
local zcompdump="$HOME/.zcompdump"
if [[ -f "$zcompdump" ]] && (( EPOCHSECONDS - $(zstat +mtime "$zcompdump") < 86400 )); then
    compinit -C -d "$zcompdump"
else
    compinit -d "$zcompdump"
fi
bindkey -e
# ===================================

# ============ Security =============
umask 022
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
# ===================================

# ============= Plugins =============
if (( $+functions[zsh_plugin_load] )); then
    zsh_plugin_load "ohmyzsh/ohmyzsh" "plugins/git/git.plugin.zsh"
    zsh_plugin_load "zsh-users/zsh-autosuggestions"
    zsh_plugin_load "zsh-users/zsh-syntax-highlighting"  # loaded last, same as defer:2
fi
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

# ============ Hacking  ============
# This section is for some wacky hacking that will make your life easier.

# SSH connection helper with search filter support
function fssh() {
    if ! command -v fzf > /dev/null 2>&1; then
        log "ERROR" "fzf is not installed. Please install fzf to use this function."
        return 1
    fi
    if [[ ! -f $HOME/.ssh/config ]]; then
        log "ERROR" "No SSH config file found at ~/.ssh/config"
        return 1
    fi
    local host search_term=""
    [[ $# -gt 0 ]] && search_term="$1"
    host=$(grep "^Host " ~/.ssh/config | grep -v "\*" | cut -d" " -f2- | fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt="SSH > " \
        --query="$search_term" \
        --preview="grep -A 2 'Host {}' ~/.ssh/config")

    if [[ -n $host ]]; then
        log "INFO" "Connecting to $host..."
        ssh "$host"
    fi
}
# USQL connection helper with search filter support
function fusql() {
    if ! command -v fzf > /dev/null 2>&1; then
        log "ERROR" "fzf is not installed. Please install fzf to use this function."
        return 1
    fi
    if ! command -v usql > /dev/null 2>&1; then
        log "ERROR" "usql is not installed. Please install usql to use this function."
        return 1
    fi

    local config_file="$HOME/.config/usql/config.yaml"
    if [[ ! -f $config_file ]]; then
        log "ERROR" "No usql config file found at $config_file"
        return 1
    fi

    local search_term="$1"
    local db

    db=$(grep -E '^\s+[a-z_][a-z0-9_]*:\s' "$config_file" | \
        sed 's/^\s*//;s/:\s.*//' | \
        fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt="USQL > " \
        --query="$search_term")

    if [[ -n $db ]]; then
        log "INFO" "Connecting to $db..."
        usql "$db"
    fi
}
# Zoxide + Tmux
function zt() {
    if ! command -v zoxide >/dev/null 2>&1; then
        log "ERROR" "zoxide is not installed. Please install zoxide to use this function."
        return 1
    fi

    if [[ -z "$TMUX" ]]; then
        log "ERROR" "Not inside a tmux session."
        return 1
    fi
    local result
    if ! result=$(zoxide query --interactive "$@"); then
        log "WARN" "zoxide query failed or was cancelled."
        return 1
    fi
    local window_name=$(basename "$result")
    tmux new-window -n "$window_name" -c "$result"
}
# Search Duckduckgo
function ddg() {
    local query="$*"
    if [[ -z "$query" ]]; then
        if command -v gum >/dev/null 2>&1; then
            query=$(gum input --placeholder "Search Unduck") || return 1
        else
            log "WARN" "Usage: ddg <search terms>"
            return 1
        fi
    fi
    local url="https://unduck.link/?q=$query"
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        if wsl-zen --check 2>/dev/null; then
            wsl-zen "$url"
        elif wsl-chrome --check 2>/dev/null; then
            wsl-chrome "$url"
        elif wsl-edge --check 2>/dev/null; then
            wsl-edge "$url"
        else
            log "ERROR" "No Windows browser found (Zen, Chrome, or Edge)."
            return 1
        fi
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url"
    elif command -v open >/dev/null 2>&1; then
        open "$url"
    elif [[ -n "$BROWSER" ]]; then
        $BROWSER "$url"
    else
        log "ERROR" "No suitable method found to open URLs."
        return 1
    fi
}
# ===================================

# ========== PATH & eval ============
# Create local directories
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SCRIPT="$HOME/.local/scripts"
LOCAL_SHARE="$HOME/.local/share"
mkdir -p "$LOCAL_BIN" "$LOCAL_SCRIPT"

function path_prepend() {
    [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}

# Extend PATH
path_prepend "$LOCAL_BIN"
path_prepend "$LOCAL_SCRIPT"

# Golang Binary
[[ -d "${GOPATH:-$HOME/go}/bin" ]] && path_prepend "${GOPATH:-$HOME/go}/bin"

# Cargo Binary
[[ -d "$HOME/.cargo/bin" ]] && path_prepend "$HOME/.cargo/bin"

# govm (Go Version Manager)
[[ -d "$HOME/.govm/shim" ]] && path_prepend "$HOME/.govm/shim"

# fnm (Fast Node Manager)
[[ -d "$LOCAL_SHARE/fnm" ]] && path_prepend "$LOCAL_SHARE/fnm" && eval "$(fnm env)"

# bun (JavaScript runtime)
[[ -d "$HOME/.bun" ]] && path_prepend "$HOME/.bun/bin"
[[ -f "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Opencode (CLI)
[[ -d "$HOME/.opencode/bin" ]] && path_prepend "$HOME/.opencode/bin"

# Starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    log "WARN" "starship not found." "https://starship.rs/"
fi
# Zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
else
    log "WARN" "zoxide not found." "https://github.com/ajeetdsouza/zoxide"
fi

# Ruby
[[ -d "$HOME/.gem/ruby/bin" ]] && path_prepend "$HOME/.gem/ruby/bin"

# Humanlog
[[ -d "$HOME/.humanlog/bin" ]] && path_prepend "$HOME/.humanlog/bin"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    export SDKMAN_DIR="$HOME/.sdkman"
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
[[ -d "$HOME/.rvm/bin" ]] && path_prepend "$HOME/.rvm/bin"

export PATH
# ===================================
