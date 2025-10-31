#!/bin/bash

# Installera Brew -----------------------------------------------------------------------------------

if command -v brew >/dev/null 2>&1; then
    echo "Homebrew är redan installerat."
else
    echo "Homebrew är inte installerat. Installerar nu..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Installationen är klar. Lägg till Homebrew till PATH om det behövs (se instruktioner i terminalen)."
fi

# Setup SSH-keys to GitHub ---------------------------------------------------------------------------

DEFAULT_NAME="Omarchy"  # Default-nyckelnamn (används alltid nu)
KEY_NAME="$DEFAULT_NAME"  # Sätt direkt till default – ingen prompt!
COMMENT="$(whoami)@$(hostname) (Omarchy $(date +%Y-%m-%d))"  # Kommentar för nyckeln
# Kontrollera att namnet inte är tomt (säkerhetskontroll, även om det är hårdkodat)
if [[ -z "$KEY_NAME" ]]; then
    echo "Fel: Namn på nyckeln får inte vara tomt!"
    exit 1
fi

SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/$KEY_NAME"
KEY_PUB="$KEY_PATH.pub"

# Skapa .ssh-katalog om den saknas
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# --- HÄMTA BEFINTLIGA NYCKLAR FRÅN GITHUB (behåll din befintliga kod här om den finns) ---
echo "Hämtar befintliga SSH-nycklar från GitHub..."
# Lägg in din curl/gh-kod för GitHub API här, om den finns i originalet

# --- GENERERA NY NYCKEL OM DEN SAKNAS ---
if [[ ! -f "$KEY_PATH" ]]; then
    echo "Genererar ny ed25519 SSH-nyckel med namnet '$KEY_NAME'..."
    if ! ssh-keygen -t ed25519 -C "$COMMENT" -f "$KEY_PATH" -N ""; then
        echo "Fel: Kunde inte generera SSH-nyckel!"
        exit 1
    fi
    chmod 600 "$KEY_PATH"
    chmod 644 "$KEY_PUB"
    echo "Nyckel genererad: $KEY_PATH"
else
    echo "SSH-nyckel finns redan: $KEY_PATH"
fi

# --- LÄS PUBLIK NYCKEL ---
if [[ ! -f "$KEY_PUB" ]]; then
    echo "Fel: Kunde inte hitta publik nyckel: $KEY_PUB"
    exit 1
fi
PUBLIC_KEY=$(cat "$KEY_PUB")
echo "Publik nyckel läst från $KEY_PUB"

# --- LÄGG TILL TILL SSH-AGENT (valfritt, men smidigt) ---
if ! pgrep -x "ssh-agent" > /dev/null; then
    eval "$(ssh-agent -s)"
fi
ssh-add "$KEY_PATH" 2>/dev/null || echo "Obs: Nyckeln lades inte till i agenten (kör 'ssh-add' manuellt om behövs)"

# --- SETUP FÖR GITHUB ---
echo "Kopiera den här publika nyckeln och lägg till på GitHub: https://github.com/settings/keys"
echo "$PUBLIC_KEY"
echo "Nyckeln '$KEY_NAME' är redo för GitHub!"

# Skapa repos-mapp --------------------------------------------------------------------------------
echo "Setting up 'repos' directory..."
mkdir "$HOME/repos"

# Klona Dotfiles ----------------------------------------------------------------------------------
if [ -d "$HOME/repos/dotfiles" ]; then
  echo "Dotfiles directory exists, pulling latest changes..."
  cd "$HOME/repos/dotfiles" && git pull
else
  echo "Cloning Dotfiles from GitHub..."
  echo
  printf "\n"
  git clone git@github.com:simonbrundin/dotfiles.git "$HOME/repos/dotfiles"
fi

# Klona Simon CLI ---------------------------------------------------------------------------------
if [ -d "$HOME/repos/simon-cli" ]; then
  echo "Simon CLI directory exists, pulling latest changes..."
  cd "$HOME/repos/simon-cli" && git pull
else
  echo "Cloning Simon CLI from GitHub..."
  git clone git@github.com:simonbrundin/simon-cli.git "$HOME/repos/simon-cli"
fi

# echo "Running simon bootstrap via nushell..."
# nu -c "$HOME/repos/simon-cli/simon bootstrap mac"
