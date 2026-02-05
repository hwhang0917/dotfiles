# Dotfiles

> Configuration files for my development environment.

## Prerequisites

- [git](https://git-scm.com/)
- [stow](https://www.gnu.org/software/stow/)

## Quick Start

```bash
git clone https://github.com/hwhang0917/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

The bootstrap script will:
1. Check for required dependencies (git, stow)
2. Initialize git submodules
3. Detect your platform and suggest packages
4. Prompt for package selection:
   - `Y` - Stow all suggested packages
   - `n` - Skip package installation
   - `custom` - Choose specific packages to stow
5. Optionally set up git local configuration

## Available Packages

### Common (all platforms)

| Package | Description |
|---------|-------------|
| git | Git configuration |
| zsh | Zsh shell configuration |
| tmux | Tmux terminal multiplexer |
| nvim | Neovim configuration |
| vim | Vim configuration |
| scripts | Utility scripts |
| tig | Tig git interface |
| yazi | Yazi file manager |

### Linux / WSL / macOS

| Package | Description |
|---------|-------------|
| ghostty | Ghostty terminal |

### Linux / WSL

| Package | Description |
|---------|-------------|
| hypr | Hyprland window manager |
| sway | Sway window manager |
| kime | Kime Korean IME |

### Windows

| Package | Description |
|---------|-------------|
| komorebi | Komorebi tiling window manager |
| glzr | Glazewm configuration |
| autohotkey | AutoHotkey scripts |

## Manual Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/hwhang0917/dotfiles.git ~/dotfiles
   ```

2. Initialize submodules:

   ```bash
   cd ~/dotfiles
   git submodule update --init --recursive
   ```

3. Stow packages:

   ```bash
   stow <package>
   ```

## Git Configuration

After stowing git, set up your local credentials:

```bash
./setup/gitconfig_init.sh
```

Or manually copy the example file:

```bash
cp ~/dotfiles/git/.gitconfig.local.example ~/.gitconfig.local
```

Edit `~/.gitconfig.local` with your name, email, and signing key.

## Uninstallation

To uninstall a package, you can use GNU Stow with the `-D` option:

```bash
stow -D <package>
```

## Troubleshooting

### Stow conflicts with existing files

If stow fails due to existing files:

```bash
stow -D <package>  # Remove any partial stow
mv ~/.config/<file> ~/.config/<file>.backup  # Backup existing file
stow <package>  # Try again
```

### zplug not found

Install zplug manually:

```bash
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
```

### Submodule issues

If submodules fail to initialize:

```bash
git submodule sync
git submodule update --init --recursive --force
```

### Missing starship/zoxide warnings

These are optional dependencies. Install them to remove warnings:

- **starship**: https://starship.rs/
- **zoxide**: https://github.com/ajeetdsouza/zoxide

### Bootstrap fails with "Missing required dependencies"

Install the prerequisites first:

```bash
# Debian/Ubuntu
sudo apt install git stow

# Arch
sudo pacman -S git stow

# macOS
brew install git stow
```

