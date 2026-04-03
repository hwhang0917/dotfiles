LOCAL_BIN="$HOME/.local/bin"
LOCAL_SCRIPT="$HOME/.local/scripts"
LOCAL_SHARE="$HOME/.local/share"
mkdir -p "$LOCAL_BIN" "$LOCAL_SCRIPT"

function path_prepend() {
    [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}

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
