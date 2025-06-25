# Hyprland configuration on UWSM
if [[ -z "$TMUX" ]]; then
    if uwsm check may-start; then
        exec uwsm start default
    fi
fi
