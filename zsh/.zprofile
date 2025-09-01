# Kime
if command -v kime >/dev/null 2>&1 && [[ -f "/usr/lib/libkime_engine.so" ]]; then
    export GTK_IM_MODULE=kime
    export QT_IM_MODULE=kime
    export XMODIFIERS=@im=kime
fi

# Hyprland configuration on UWSM
if [[ -z "$TMUX" ]]; then
    if command -v uwsm >/dev/null 2>&1; then
        if uwsm check may-start; then
            exec uwsm start default
        fi
    fi
fi
