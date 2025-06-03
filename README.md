# Dotfiles

> Configuration files for my development environment.

## Prerequisites

- [stow](https://www.gnu.org/software/stow/)

## Installation


1. Clone the repository in the home directory:

   ```bash
   git clone https://github.com/hwhang0917/dotfiles.git ~/dotfiles
   ```

2. Fetch submodules:

   ```bash
   cd dotfiles
   git submodule update --init --recursive
   ```

   This will ensure that all the necessary submodules are cloned, such as `nvim`, `zsh`, etc.

3. Install the dotfiles using GNU Stow:

   ```bash
   cd dotfiles
   stow <package>
   ```

   Replace `<package>` with the name of the package you want to install (e.g., `nvim`, `zsh`, etc.).
