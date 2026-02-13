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
   | [gum](https://github.com/charmbracelet/gum) | Shell scripting toolkit | pacman / brew / go install |
   | [starship](https://starship.rs/) | Prompt | pacman / brew / install script |
   | [fnm](https://github.com/Schniz/fnm) | Fast Node Manager | pacman / brew / install script |
   | [zplug](https://github.com/zplug/zplug) | Zsh plugin manager | pacman / brew / install script |

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
| Windows | komorebi, glzr, autohotkey |

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

Windows does not support GNU Stow. Use symbolic links manually instead.

1. Clone the repository:

   ```powershell
   git clone https://github.com/hwhang0917/dotfiles.git $HOME\dotfiles
   cd $HOME\dotfiles
   git submodule update --init --recursive
   ```

2. Create symbolic links (run PowerShell as Administrator):

   ```powershell
   # Komorebi
   New-Item -ItemType SymbolicLink -Path "$HOME\.config\komorebi" -Target "$HOME\dotfiles\komorebi\.config\komorebi"

   # GlazeWM
   New-Item -ItemType SymbolicLink -Path "$HOME\.glzr" -Target "$HOME\dotfiles\glzr\.glzr"

   # AutoHotkey (adjust path as needed)
   New-Item -ItemType SymbolicLink -Path "$HOME\Documents\AutoHotkey" -Target "$HOME\dotfiles\autohotkey\Documents\AutoHotkey"
   ```

   Or use `mklink` in Command Prompt (as Administrator):

   ```cmd
   mklink /D "%USERPROFILE%\.config\komorebi" "%USERPROFILE%\dotfiles\komorebi\.config\komorebi"
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
