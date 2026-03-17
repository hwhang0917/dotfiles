#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install URLs (update these when upstream changes)
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

HAS_GUM=false

TMPDIR_BOOTSTRAP=""
cleanup() { [[ -n "$TMPDIR_BOOTSTRAP" ]] && rm -rf "$TMPDIR_BOOTSTRAP"; }
trap cleanup EXIT

# ── Prompts (gum with read fallback) ──────────────────────────

confirm() {
    local prompt="$1"
    if $HAS_GUM; then
        gum confirm "$prompt"
    else
        read -rp "$prompt [Y/n]: " choice
        choice="${choice:-y}"
        [[ "$choice" =~ ^[Yy] ]]
    fi
}

# Multi-select from a list. Pre-selected items passed via --selected.
# Prints selected items, one per line.
choose_many() {
    local header="$1"
    shift
    local selected="$1"
    shift
    local items=("$@")

    if $HAS_GUM; then
        local args=(--no-limit --header "$header")
        [[ -n "$selected" ]] && args+=(--selected "$selected")
        printf '%s\n' "${items[@]}" | gum choose "${args[@]}"
    else
        echo "$header" >&2
        echo "(space-separated, or 'all' for everything)" >&2
        for item in "${items[@]}"; do
            echo "  - $item" >&2
        done
        read -rp "> " input
        if [[ "$input" == "all" ]]; then
            printf '%s\n' "${items[@]}"
        else
            echo "$input" | tr ' ' '\n'
        fi
    fi
}

# ── Utilities ─────────────────────────────────────────────────

check_dependencies() {
    local missing=()
    for cmd in git stow curl; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
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

detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)  echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# ── Gum bootstrap ────────────────────────────────────────────

ensure_gum() {
    if command -v gum &>/dev/null; then
        HAS_GUM=true
        return
    fi

    log_step "gum not found — installing for interactive prompts..."

    local installed=false
    if command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm gum &>/dev/null && installed=true
    elif command -v brew &>/dev/null; then
        brew install gum &>/dev/null && installed=true
    elif command -v go &>/dev/null; then
        go install github.com/charmbracelet/gum@latest &>/dev/null && installed=true
    fi

    if $installed && command -v gum &>/dev/null; then
        HAS_GUM=true
        log_info "gum installed"
    else
        log_warn "Could not install gum, falling back to basic prompts"
    fi
}

# ── Package name mapping ─────────────────────────────────────

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

# ── Tool installation ─────────────────────────────────────────

install_tool() {
    local tool="$1" platform="$2"

    # Try package manager first
    case "$platform" in
        linux|wsl)
            if command -v pacman &>/dev/null; then
                local pkg; pkg=$(pkg_name pacman "$tool")
                if [[ -n "$pkg" ]]; then
                    try_install "$tool" sudo pacman -S --needed --noconfirm "$pkg"
                    return
                fi
            elif command -v apt &>/dev/null; then
                local pkg; pkg=$(pkg_name apt "$tool")
                if [[ -n "$pkg" ]]; then
                    try_install "$tool" sudo apt install -y "$pkg"
                    return
                fi
            fi
            ;;
        macos)
            if command -v brew &>/dev/null; then
                local pkg; pkg=$(pkg_name brew "$tool")
                if [[ -n "$pkg" ]]; then
                    try_install "$tool" brew install "$pkg"
                    return
                fi
            fi
            ;;
    esac

    # Fallback to install scripts
    case "$tool" in
        starship) try_install starship download_and_exec "$STARSHIP_INSTALL_URL" sh -s -- -y ;;
        zoxide)   try_install zoxide download_and_exec "$ZOXIDE_INSTALL_URL" sh ;;
        fnm)      try_install fnm download_and_exec "$FNM_INSTALL_URL" bash -s -- --skip-shell ;;
        eza)
            if command -v cargo &>/dev/null; then
                try_install eza cargo install eza
            else
                log_warn "eza requires cargo, skipping"
            fi
            ;;
        *)
            log_warn "No auto-install method for $tool"
            ;;
    esac
}

install_optional_deps() {
    local platform="$1"
    local all_deps=(fzf zoxide eza bat starship fnm)

    log_step "Checking optional dependencies..."
    local missing=()
    for cmd in "${all_deps[@]}"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_info "All optional dependencies already installed"
        return
    fi

    local selected
    selected=$(choose_many "Select tools to install:" "$(IFS=,; echo "${missing[*]}")" "${missing[@]}") || return 0

    [[ -z "$selected" ]] && return

    while IFS= read -r tool; do
        [[ -n "$tool" ]] && install_tool "$tool" "$platform"
    done <<< "$selected"
}

# ── Submodules ────────────────────────────────────────────────

init_submodules() {
    log_step "Initializing git submodules..."
    cd "$DOTFILES_DIR"
    git submodule update --init --recursive
    log_info "Submodules initialized"
}

# ── Stow ──────────────────────────────────────────────────────

stow_package() {
    local package="$1"
    if [[ -d "$DOTFILES_DIR/$package" ]]; then
        log_info "Stowing $package..."
        stow -d "$DOTFILES_DIR" -t "$HOME" "$package"
    else
        log_warn "Package $package not found"
    fi
}

interactive_stow() {
    local platform="$1"

    # All available stow packages
    local available=()
    for dir in "$DOTFILES_DIR"/*/; do
        local dir_name
        dir_name=$(basename "$dir")
        [[ "$dir_name" =~ ^(assets|src|bin|windows|\.claude)$ ]] && continue
        available+=("$dir_name")
    done

    # Platform-suggested packages (pre-selected in gum)
    local suggested=()
    local common=(git zsh tmux nvim vim scripts tig yazi bat starship)
    suggested+=("${common[@]}")

    case "$platform" in
        linux)  suggested+=(hypr sway ghostty kime) ;;
        macos)  suggested+=(ghostty) ;;
    esac

    log_step "Platform detected: $platform"

    local selected
    selected=$(choose_many "Select packages to stow:" "$(IFS=,; echo "${suggested[*]}")" "${available[@]}") || return 0

    [[ -z "$selected" ]] && return

    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && stow_package "$pkg"
    done <<< "$selected"
}

# ── Git config ────────────────────────────────────────────────

setup_git_config() {
    if [[ -f "$HOME/.gitconfig" ]] && [[ ! -f "$HOME/.gitconfig.local" ]]; then
        log_warn "~/.gitconfig.local not found"
        log_info "Copy the example and fill in your details:"
        log_info "  cp $DOTFILES_DIR/git/.gitconfig.local.example ~/.gitconfig.local"
    fi
}

# ── Main ──────────────────────────────────────────────────────

main() {
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║         Dotfiles Bootstrap            ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""

    check_dependencies

    local platform
    platform=$(detect_platform)

    ensure_gum
    init_submodules
    install_optional_deps "$platform"
    interactive_stow "$platform"
    setup_git_config

    echo ""
    log_info "Bootstrap complete!"
}

main "$@"
