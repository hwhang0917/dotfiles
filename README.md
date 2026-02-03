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
- Initialize git submodules
- Detect your platform (Linux/WSL/macOS/Windows)
- Suggest appropriate packages to stow
- Optionally set up git local configuration

## Manual Installation

1. Clone the repository in the home directory:

   ```bash
   git clone https://github.com/hwhang0917/dotfiles.git ~/dotfiles
   ```

2. Fetch submodules:

   ```bash
   cd ~/dotfiles
   git submodule update --init --recursive
   ```

3. Install the dotfiles using GNU Stow:

   ```bash
   stow <package>
   ```

   Replace `<package>` with the name of the package you want to install (e.g., `nvim`, `zsh`, etc.).

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

