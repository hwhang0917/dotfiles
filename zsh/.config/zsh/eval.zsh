# Starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    print -u2 "[WARN] starship not found. https://starship.rs/"
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
else
    print -u2 "[WARN] zoxide not found. https://github.com/ajeetdsouza/zoxide"
fi
