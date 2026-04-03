# Starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    log "WARN" "starship not found." "https://starship.rs/"
fi

# fnm (Fast Node Manager)
if command -v fnm >/dev/null 2>&1; then
    _fnm_env=$(fnm env 2>/dev/null) || {
        _fnm_shell=$(cat /proc/$$/comm 2>/dev/null || ps -p $$ -o comm= 2>/dev/null)
        case "$_fnm_shell" in
            bash|zsh|fish) _fnm_env=$(fnm env --shell "$_fnm_shell") ;;
            *) log "ERROR" "fnm: unsupported shell '$_fnm_shell'" ;;
        esac
        unset _fnm_shell
    }
    [ -n "$_fnm_env" ] && eval "$_fnm_env"
    unset _fnm_env
else
    log "WARN" "fnm not found." "https://github.com/Schniz/fnm"
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
else
    log "WARN" "zoxide not found." "https://github.com/ajeetdsouza/zoxide"
fi
