#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

log_info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }
log_step()  { echo -e "${BLUE}[STEP]${RESET} $1"; }

check_dependencies() {
    local missing=()
    for cmd in git stow; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        exit 1
    fi
}

detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

init_submodules() {
    log_step "Initializing git submodules..."
    cd "$DOTFILES_DIR"
    git submodule update --init --recursive
    log_info "Submodules initialized"
}

stow_package() {
    local package="$1"
    if [[ -d "$DOTFILES_DIR/$package" ]]; then
        log_info "Stowing $package..."
        stow -d "$DOTFILES_DIR" -t "$HOME" "$package"
    else
        log_warn "Package $package not found"
    fi
}

select_packages() {
    local platform="$1"
    local packages=()

    local common_packages=(git zsh tmux nvim vim scripts tig yazi)
    packages+=("${common_packages[@]}")

    case "$platform" in
        linux|wsl)
            packages+=(hypr sway ghostty kime)
            ;;
        macos)
            packages+=(ghostty)
            ;;
        windows)
            packages+=(komorebi glzr autohotkey)
            ;;
    esac

    echo "${packages[@]}"
}

interactive_stow() {
    local platform="$1"
    local suggested_packages
    suggested_packages=$(select_packages "$platform")

    echo ""
    log_step "Platform detected: $platform"
    echo "Suggested packages: $suggested_packages"
    echo ""

    read -rp "Stow suggested packages? [Y/n/custom]: " choice
    choice="${choice:-y}"

    case "$choice" in
        [Yy]*)
            for pkg in $suggested_packages; do
                stow_package "$pkg"
            done
            ;;
        [Nn]*)
            log_info "Skipping package installation"
            return
            ;;
        *)
            echo "Available packages:"
            for dir in "$DOTFILES_DIR"/*/; do
                dir_name=$(basename "$dir")
                [[ "$dir_name" =~ ^(setup|packages)$ ]] && continue
                echo "  - $dir_name"
            done
            echo ""
            read -rp "Enter packages to stow (space-separated): " custom_packages
            for pkg in $custom_packages; do
                stow_package "$pkg"
            done
            ;;
    esac
}

setup_git_config() {
    if [[ -f "$HOME/.gitconfig" ]] && [[ ! -f "$HOME/.gitconfig.local" ]]; then
        log_step "Setting up git local config..."
        read -rp "Run gitconfig_init.sh to create .gitconfig.local? [Y/n]: " choice
        choice="${choice:-y}"
        if [[ "$choice" =~ ^[Yy] ]]; then
            "$DOTFILES_DIR/setup/gitconfig_init.sh"
        else
            log_info "Skipped. You can run ./setup/gitconfig_init.sh later"
            log_info "Or copy git/.gitconfig.local.example to ~/.gitconfig.local"
        fi
    fi
}

main() {
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║         Dotfiles Bootstrap            ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""

    check_dependencies

    local platform
    platform=$(detect_platform)

    init_submodules
    interactive_stow "$platform"
    setup_git_config

    echo ""
    log_info "Bootstrap complete!"
}

main "$@"
