<p align="center">
  <img src="assets/runfridge.jpg" alt="profile image of running refrigerator" width="200">
</p>

# Dotfiles

> Configuration files for my development environment.

![GitHub License](https://img.shields.io/github/license/hwhang0917/dotfiles)

## Supported Platforms

| Family | Distros | Package manager |
|--------|---------|-----------------|
| **Arch** | Arch, Manjaro, EndeavourOS | `pacman` |
| **RHEL** | Rocky, Alma, Fedora, RHEL, CentOS Stream | `dnf` + EPEL |
| **Debian** | Debian, Ubuntu, Mint, Pop!_OS | `apt` |
| **macOS** | macOS | `brew` |
| **Windows** | Windows 10/11 | `winget` (via `bootstrap.ps1`) |

## Prerequisites

- [git](https://git-scm.com/)
- [zsh](https://www.zsh.org/)
- [stow](https://www.gnu.org/software/stow/)
- [curl](https://curl.se/)

> The bootstrap script will attempt to install missing prerequisites automatically.

## Quick Start

```bash
git clone https://github.com/hwhang0917/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

The bootstrap script will:

1. Check for required dependencies (git, stow, curl)
2. Detect your platform (linux, wsl, macos, windows)
3. Install [gum](https://github.com/charmbracelet/gum) for interactive prompts (falls back to basic `read` if unavailable)
4. Initialize git submodules
5. Interactively select optional tools to install:

   | Tool | Description | Install method |
   |------|-------------|----------------|
   | [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | pacman / apt / brew |
   | [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter cd | pacman / brew / install script |
   | [eza](https://github.com/eza-community/eza) | Modern ls | pacman / brew / cargo |
   | [bat](https://github.com/sharkdp/bat) | Modern cat | pacman / apt / brew |
   | [starship](https://starship.rs/) | Prompt | pacman / brew / install script |
   | [fnm](https://github.com/Schniz/fnm) | Fast Node Manager | pacman / brew / install script |

6. Interactively select stow packages (platform defaults pre-selected)
7. Remind to set up git local configuration if missing

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
cp ~/dotfiles/git/.gitconfig.local.example ~/.gitconfig.local
```

Edit `~/.gitconfig.local` with your name, email, and signing key:

```gitconfig
[credential "https://github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
    helper =
    helper = !/usr/bin/gh auth git-credential
[user]
    name = Your Name
    email = your.email@example.com
    signingKey = ~/.ssh/id_ed25519.pub
```

Optionally add `includeIf` for work-specific configs:

```gitconfig
[includeIf "gitdir:~/work/"]
    path = ~/work/.gitconfig
```

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
