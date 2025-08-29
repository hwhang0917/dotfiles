# ============ Utility ==============
function log() {
    local GREEN='\033[32m'
    local YELLOW='\033[33m'
    local RED='\033[31m'
    local BLUE='\033[34m'
    local RESET='\033[0m'

    local msg_type="$1"
    local msg="$2"

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
}
# ===================================

# ============== Init ===============
[[ -f $HOME/.zplug/init.zsh ]] && source $HOME/.zplug/init.zsh || {
    log "WARN" "zplug not found. Install with: "
    log "INFO" "curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh"
}
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

# Browser preference
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    export BROWSER="$HOME/.local/bin/wsl-zen"
fi

# Podman settings
export PODMAN_COMPOSE_WARNING_LOGS=false
# ===================================

# ============= Plugins =============
if command -v zplug >/dev/null 2>&1; then
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
fi
# ===================================

# ============= Aliases =============
# Common aliases
alias l="ls -lah"
alias ll="ls -lh"
alias la="ls -lAh"

# OS-Specific aliases
case "$(uname -s)" in
    Linux)
        if command -v pacman >/dev/null 2>&1; then
            alias p="sudo pacman"
            alias p-clean="sudo paccache -r && sudo pacman -Sc && sudo yay -Sc"
        fi
        ;;
esac

# Editor aliases
if command -v nvim > /dev/null 2>&1; then
    alias vi="nvim"
    alias vim="nvim"
fi

# GNU tool modern replacements
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --icons --git"
    alias ll="ls -lh"
    alias la="ls -lAh"
elif command -v exa >/dev/null 2>&1; then
    alias ls="exa --icons --git"
    alias ll="ls -lh"
    alias la="ls -lAh"
else
    alias ls="ls --color=auto"
    alias ll="ls -lh --color=auto"
    alias la="ls -lAh --color=auto"
fi

if command -v bat >/dev/null 2>&1; then
    alias cat="bat"
fi

# Deprecation aliases
alias sxiv="nsxiv"
# ===================================

# ============ Hacking  ============
# This section is for some wacky hacking that will make your life easier.

# NetworkManager TUI is hard to read in catppuccin theme, so we change the colors.
function nmtui() {
    if command -v nmtui >/dev/null 2>&1; then
        NEWT_COLORS="root=white,black;window=white,black;border=yellow,black;listbox=white,black;label=white,black;checkbox=white,black;compactbutton=white,black;textbox=yellow,black;entry=yellow,black;editline=yellow,black" nmtui
    else
        log "ERROR" "nmtui command not found."
    fi
}
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
        --preview="grep -A 4 'Host {}' ~/.ssh/config")

    if [[ -n $host ]]; then
        log "INFO" "Connecting to $host..."
        ssh "$host"
    fi
}
# Zoxide + Tmux
function zt() {
    if ! command -v zoxide >/dev/null 2>&1; then
        log "ERROR" "zoxide is not installed. Please install zoxide to use this function."
        return 1
    fi

    if [ -z "$TMUX" ]; then
        log "ERROR" "Not inside a tmux session."
        return 1
    fi
    local result
    if [ -z "$1" ]; then
        result=$(zoxide query --interactive)
    else
        result=$(zoxide query --interactive "$1")
    fi
    if [ $? -ne 0 ]; then
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
            query=$(gum input --placeholder "Search DuckDuckGo") || return 1
        else
            log "WARN" "Usage: ddg <search terms>"
            return 1
        fi
    fi
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "https://duckduckgo.com/?q=$query"
    elif command -v open >/dev/null 2>&1; then
        open "https://duckduckgo.com/?q=$query"
    elif [[ -n "$BROWSER" ]]; then
        $BROWSER "https://duckduckgo.com/?q=$query"
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
if command -v go >/dev/null 2>&1; then
    GOBIN="$(go env GOPATH)/bin"
    path_prepend "$GOBIN"
fi

# govm (Go Version Manager)
if command -v govm >/dev/null 2>&1; then
    path_prepend "$HOME/.govm/shim"
fi

# fnm (Fast Node Manager)
[[ -d "$LOCAL_SHARE/fnm" ]] && path_prepend "$LOCAL_SHARE/fnm"
if command -v fnm >/dev/null 2>&1; then
    path_prepend "$HOME/.local/share/fnm"
    eval "$(fnm env)"
fi

# bun (JavaScript runtime)
if command -v bun >/dev/null 2>&1; then
    export BUN_INSTALL="$HOME/.bun"
    path_prepend "$BUN_INSTALL/bin"
    # bun completions
    [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
fi

# Starship
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
# Zoxide
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
# GH CLI
command -v gh >/dev/null 2>&1 && eval "$(gh copilot alias -- zsh)"

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
