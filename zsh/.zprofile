# Hyprland configuration on UWSM
if [[ -z "$TMUX" ]]; then
    if command -v uwsm >/dev/null 2>&1; then
        if uwsm check may-start; then
            exec uwsm start default
        fi
    fi
fi
