#!/bin/bash
# echo "version: 0.0.1"
# read -r -p "Ange användarnamn till GitHub: " GITHUB_USERNAME

# Konfigurera datorns dotfiles via Chezmoi
# sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "$GITHUB_USERNAME"

# echo "Installing Devbox..."
# curl -fsSL https://get.jetify.com/devbox | bash
#
# echo "Installing Nushell via devbox global..."
# devbox global add nushell

# Skapa repos-mapp
echo "Setting up 'repos' directory..."
mkdir "$HOME/repos"

# Klona Dotfiles
if [ -d "$HOME/repos/dotfiles" ]; then
  echo "Dotfiles directory exists, pulling latest changes..."
  cd "$HOME/repos/dotfiles" && git pull
else
  echo "Cloning Dotfiles from GitHub..."
  printf "\n"
  git clone https://github.com/simon/dotfiles "$HOME/repos/dotfiles"
fi

# Klona Simon CLI
if [ -d "$HOME/repos/simon-cli" ]; then
  echo "Simon CLI directory exists, pulling latest changes..."
  cd "$HOME/repos/simon-cli" && git pull
else
  echo "Cloning Simon CLI from GitHub..."
  git clone https://github.com/simon/simon-cli "$HOME/repos/simon-cli"
fi

# echo "Running simon bootstrap via nushell..."
# nu -c "$HOME/repos/simon-cli/simon bootstrap mac"
