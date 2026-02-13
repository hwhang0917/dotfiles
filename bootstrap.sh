#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install URLs (update these when upstream changes)
ZPLUG_INSTALL_URL="https://raw.githubusercontent.com/zplug/installer/master/installer.zsh"
STARSHIP_INSTALL_URL="https://starship.rs/install.sh"
ZOXIDE_INSTALL_URL="https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
FNM_INSTALL_URL="https://fnm.vercel.app/install"

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

log_info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }
log_step()  { echo -e "${BLUE}[STEP]${RESET} $1"; }

TMPDIR_BOOTSTRAP=""
cleanup() { [[ -n "$TMPDIR_BOOTSTRAP" ]] && rm -rf "$TMPDIR_BOOTSTRAP"; }
trap cleanup EXIT

check_dependencies() {
    local missing=()
    for cmd in git stow curl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        exit 1
    fi
}

download_and_exec() {
    local url="$1"
    shift
    local shell_cmd=("$@")

    TMPDIR_BOOTSTRAP="${TMPDIR_BOOTSTRAP:-$(mktemp -d)}"
    local tmpfile="$TMPDIR_BOOTSTRAP/installer_$$_$RANDOM"

    if ! curl -fsSL --retry 3 --retry-delay 2 -o "$tmpfile" "$url"; then
        log_error "Failed to download: $url"
        return 1
    fi

    if [[ ! -s "$tmpfile" ]]; then
        log_error "Downloaded empty file from: $url"
        return 1
    fi

    "${shell_cmd[@]}" "$tmpfile"
}

try_install() {
    local name="$1"
    shift
    log_info "Installing $name..."
    if "$@"; then
        log_info "$name installed"
    else
        log_warn "Failed to install $name, skipping"
    fi
}

# Maps command name -> package name per manager
pkg_name() {
    local manager="$1" cmd="$2"
    case "$manager:$cmd" in
        pacman:bat)      echo "bat" ;;
        pacman:eza)      echo "eza" ;;
        pacman:fzf)      echo "fzf" ;;
        pacman:gum)      echo "gum" ;;
        pacman:zoxide)   echo "zoxide" ;;
        pacman:starship) echo "starship" ;;
        pacman:fnm)      echo "fnm" ;;
        apt:bat)         echo "bat" ;;
        apt:fzf)         echo "fzf" ;;
        brew:*)          echo "$cmd" ;;
        *)               echo "" ;;
    esac
}

install_optional_deps() {
    local platform="$1"
    local deps=(fzf zoxide eza bat gum starship fnm zplug)

    log_step "Checking optional dependencies..."
    local missing=()
    for cmd in "${deps[@]}"; do
        case "$cmd" in
            zplug) [[ -d "$HOME/.zplug" ]] || missing+=("$cmd") ;;
            *)     command -v "$cmd" &>/dev/null || missing+=("$cmd") ;;
        esac
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_info "All optional dependencies already installed"
        return
    fi

    log_warn "Missing optional tools: ${missing[*]}"
    read -rp "Install missing tools? [Y/n]: " choice
    choice="${choice:-y}"
    [[ ! "$choice" =~ ^[Yy] ]] && return

    case "$platform" in
        linux|wsl)
            if command -v pacman &>/dev/null; then
                install_deps_pacman "${missing[@]}"
            elif command -v apt &>/dev/null; then
                install_deps_apt "${missing[@]}"
            else
                log_warn "Unsupported package manager, install manually: ${missing[*]}"
            fi
            ;;
        macos)
            if command -v brew &>/dev/null; then
                install_deps_brew "${missing[@]}"
            else
                log_warn "Homebrew not found, install manually: ${missing[*]}"
            fi
            ;;
        *)
            log_warn "Unsupported platform for auto-install: ${missing[*]}"
            ;;
    esac
}

install_deps_pacman() {
    local tools=("$@")
    local pacman_pkgs=()
    local manual=()

    for tool in "${tools[@]}"; do
        local pkg
        pkg=$(pkg_name pacman "$tool")
        if [[ -n "$pkg" ]]; then
            pacman_pkgs+=("$pkg")
        else
            manual+=("$tool")
        fi
    done

    if [[ ${#pacman_pkgs[@]} -gt 0 ]]; then
        sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}" || log_warn "Some pacman packages failed"
    fi

    for tool in "${manual[@]}"; do
        install_with_script "$tool"
    done
}

install_deps_apt() {
    local tools=("$@")
    local apt_pkgs=()
    local manual=()

    for tool in "${tools[@]}"; do
        local pkg
        pkg=$(pkg_name apt "$tool")
        if [[ -n "$pkg" ]]; then
            apt_pkgs+=("$pkg")
        else
            manual+=("$tool")
        fi
    done

    if [[ ${#apt_pkgs[@]} -gt 0 ]]; then
        sudo apt update && sudo apt install -y "${apt_pkgs[@]}" || log_warn "Some apt packages failed"
    fi

    for tool in "${manual[@]}"; do
        install_with_script "$tool"
    done
}

install_deps_brew() {
    local tools=("$@")
    local manual=()

    for tool in "${tools[@]}"; do
        local pkg
        pkg=$(pkg_name brew "$tool")
        if [[ -n "$pkg" ]]; then
            try_install "$tool" brew install "$pkg"
        else
            manual+=("$tool")
        fi
    done

    for tool in "${manual[@]}"; do
        install_with_script "$tool"
    done
}

install_with_script() {
    local tool="$1"
    case "$tool" in
        starship) try_install starship download_and_exec "$STARSHIP_INSTALL_URL" sh -s -- -y ;;
        zoxide)   try_install zoxide download_and_exec "$ZOXIDE_INSTALL_URL" sh ;;
        fnm)      try_install fnm download_and_exec "$FNM_INSTALL_URL" bash -s -- --skip-shell ;;
        zplug)    try_install zplug download_and_exec "$ZPLUG_INSTALL_URL" zsh ;;
        eza)
            if command -v cargo &>/dev/null; then
                try_install eza cargo install eza
            else
                log_warn "eza requires cargo, skipping"
            fi
            ;;
        gum)
            if command -v go &>/dev/null; then
                try_install gum go install github.com/charmbracelet/gum@latest
            else
                log_warn "gum requires go, skipping"
            fi
            ;;
        *)
            log_warn "No auto-install method for $tool"
            ;;
    esac
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
        wsl)
            packages+=()
            ;;
        linux)
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
    install_optional_deps "$platform"
    interactive_stow "$platform"
    setup_git_config

    echo ""
    log_info "Bootstrap complete!"
}

main "$@"
