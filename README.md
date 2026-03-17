<p align="center">
  <img src="assets/runfridge.jpg" alt="profile image of running refrigerator" width="200">
</p>

# Dotfiles

> Configuration files for my development environment.

![GitHub License](https://img.shields.io/github/license/hwhang0917/dotfiles)

## Prerequisites

- [git](https://git-scm.com/)
- [stow](https://www.gnu.org/software/stow/)
- [curl](https://curl.se/)

## Quick Start

```bash
git clone https://github.com/hwhang0917/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

The bootstrap script will:

1. Check for required dependencies (git, stow, curl)
2. Initialize git submodules
3. Detect your platform (linux, wsl, macos, windows)
4. Check for optional tools and offer to install missing ones:

   | Tool | Description | Install method |
   |------|-------------|----------------|
   | [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | pacman / apt / brew |
   | [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter cd | pacman / brew / install script |
   | [eza](https://github.com/eza-community/eza) | Modern ls | pacman / brew / cargo |
   | [bat](https://github.com/sharkdp/bat) | Modern cat | pacman / apt / brew |
   | [starship](https://starship.rs/) | Prompt | pacman / brew / install script |
   | [fnm](https://github.com/Schniz/fnm) | Fast Node Manager | pacman / brew / install script |

5. Prompt for stow package selection:
   - `Y` - Stow all suggested packages for your platform
   - `n` - Skip package installation
   - `custom` - Choose specific packages to stow
6. Optionally set up git local configuration

### Platform packages

| Platform | Stow packages |
|----------|---------------|
| Common (all) | git, zsh, tmux, nvim, vim, scripts, tig, yazi |
| Linux | hypr, sway, ghostty, kime |
| WSL | _(common only)_ |
| macOS | ghostty |
| Windows | _(use `bootstrap.ps1`)_ |

## Manual Installation

### Linux / macOS / WSL

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

### Windows

Windows does not support GNU Stow. Use `bootstrap.ps1` instead (requires Administrator):

```powershell
# Run PowerShell as Administrator
git clone https://github.com/hwhang0917/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\bootstrap.ps1
```

The script will install tools via winget (Git, Neovim, AutoHotkey, GlazeWM, Zebar, fnm, fzf, Starship), install Node.js LTS via fnm, initialize submodules, build the Zebar widget, create symlinks, and set up git local config.

#### Create-Symlink.ps1

`windows/scripts/Create-Symlink.ps1` is a lightweight alternative to GNU Stow for Windows. It creates symbolic links and requires Administrator privileges.

```powershell
.\windows\scripts\Create-Symlink.ps1 <target> <symlink>
```

If `<symlink>` is a directory, the symlink is created inside it using the target's filename.

```powershell
# Create symlink at an explicit path
.\windows\scripts\Create-Symlink.ps1 .\windows\scripts\Create-Symlink.ps1 C:\bin\Create-Symlink.ps1

# Create symlink inside a directory (C:\bin\Create-Symlink.ps1)
.\windows\scripts\Create-Symlink.ps1 .\windows\scripts\Create-Symlink.ps1 C:\bin\
```

- Errors early if not running as Administrator
- Skips if an identical symlink already exists
- Prompts before replacing a symlink that points to a different target
- Creates parent directories as needed

## Neovim

See [nvim/.config/nvim/README.md](nvim/.config/nvim/README.md) for setup, requirements, and local configuration.

## Git Configuration

After stowing git (or running `bootstrap.ps1`), set up your local credentials:

```bash
# Linux / macOS / WSL
./setup/gitconfig_init.sh

# Windows (PowerShell)
.\setup\gitconfig_init.ps1
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

### Submodule issues

If submodules fail to initialize:

```bash
git submodule sync
git submodule update --init --recursive --force
```

### Missing optional tool warnings

The bootstrap script can install these automatically. To re-run just the install step:

```bash
./bootstrap.sh
```

Or install manually — see the [optional tools table](#quick-start) above for links.

### Bootstrap fails with "Missing required dependencies"

Install the prerequisites first:

```bash
# Debian/Ubuntu
sudo apt install git stow curl

# Arch
sudo pacman -S git stow curl

# macOS
brew install git stow curl
```
