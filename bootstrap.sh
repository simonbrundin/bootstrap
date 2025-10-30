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

# Setup SSH-keys to GitHub

# Standardnamn för nyckeln
DEFAULT_NAME="Omarchy"
KEY_NAME=""

# Fråga efter namn på nyckeln
echo -n "Ange namn på SSH-nyckeln [default: $DEFAULT_NAME]: "
read USER_INPUT

# Använd default om tom inmatning
if [[ -z "$USER_INPUT" ]]; then
    KEY_NAME="$DEFAULT_NAME"
else
    KEY_NAME="$USER_INPUT"
fi

# Sök efter befintlig nyckel med det namnet
KEY_PATH="$HOME/.ssh/id_ed25519"
PUB_KEY_PATH="$KEY_PATH.pub"

if [[ -f "$PUB_KEY_PATH" ]]; then
    EXISTING_TITLE=$(gh ssh-key list | grep "$KEY_NAME" | awk '{print $1}' || true)
    if [[ -n "$EXISTING_TITLE" ]]; then
        echo "En SSH-nyckel med namnet '$KEY_NAME' finns redan på GitHub."
        read -p "Vill du överskriva den? (y/N): " OVERWRITE
        if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
            echo "Avbryter."
            exit 0
        fi
        # Ta bort befintlig nyckel
        gh ssh-key delete "$EXISTING_TITLE" --yes
    fi
else
    echo "Genererar ny SSH-nyckel med namnet '$KEY_NAME'..."
    ssh-keygen -t ed25519 -C "$KEY_NAME" -f "$KEY_PATH" -N ""
fi

# Kontrollera att gh är installerat
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) är inte installerat. Installera från https://cli.github.com"
    exit 1
fi

# Se till att du är inloggad
if ! gh auth status &> /dev/null; then
    echo "Du är inte inloggad på GitHub CLI. Kör 'gh auth login' först."
    exit 1
fi

# Ladda upp nyckeln
echo "Laddar upp SSH-nyckeln till GitHub som '$KEY_NAME'..."
cat "$PUB_KEY_PATH" | gh ssh-key add -t "$KEY_NAME"

echo "✅ SSH-nyckeln '$KEY_NAME' har laddats upp till GitHub!"
echo "Testa anslutningen med: ssh -T git@github.com"



# Skapa repos-mapp
echo "Setting up 'repos' directory..."
mkdir "$HOME/repos"

# Klona Dotfiles
if [ -d "$HOME/repos/dotfiles" ]; then
  echo "Dotfiles directory exists, pulling latest changes..."
  cd "$HOME/repos/dotfiles" && git pull
else
  echo "Cloning Dotfiles from GitHub..."
  echo
  printf "\n"
  git clone git@github.com:simonbrundin/dotfiles.git "$HOME/repos/dotfiles"
fi

# Klona Simon CLI
if [ -d "$HOME/repos/simon-cli" ]; then
  echo "Simon CLI directory exists, pulling latest changes..."
  cd "$HOME/repos/simon-cli" && git pull
else
  echo "Cloning Simon CLI from GitHub..."
  git clone git@github.com:simonbrundin/simon-cli.git "$HOME/repos/simon-cli"
fi

# echo "Running simon bootstrap via nushell..."
# nu -c "$HOME/repos/simon-cli/simon bootstrap mac"
