#!/bin/bash
set -e  # Avbryt vid fel
# echo "version: 0.0.1"
# read -r -p "Ange användarnamn till GitHub: " GITHUB_USERNAME

# Konfigurera datorns dotfiles via Chezmoi
# sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "$GITHUB_USERNAME"

# echo "Installing Devbox..."
# curl -fsSL https://get.jetify.com/devbox | bash
#
# echo "Installing Nushell via devbox global..."
# devbox global add nushell
# Installera Brew -----------------------------------------------
if command -v brew >/dev/null 2>&1; then
    echo "Homebrew är redan installerat."
else
    echo "Homebrew är inte installerat. Installerar nu..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Installationen är klar. Lägg till Homebrew till PATH om det behövs (se instruktioner i terminalen)."
fi

# Setup SSH-keys to GitHub
# --- FRÅGA EFTER NAMN ---
echo -n "Ange namn på SSH-nyckeln [default: $DEFAULT_NAME]: "
read USER_INPUT
KEY_NAME="${USER_INPUT:-$DEFAULT_NAME}"  # Lägg till ':' här!

KEY_PATH="$HOME/.ssh/id_ed25519"
PUB_KEY_PATH="$KEY_PATH.pub"

# --- 1. Kontrollera inloggning ---
if ! gh auth status >/dev/null 2>&1; then
    echo "Du är inte inloggad på GitHub CLI."
    echo "Kör: gh auth login"
    exit 1
fi

# --- 2. Hämta befintliga nycklar ---
echo "Hämtar befintliga SSH-nycklar från GitHub..."
AUTH_KEYS_JSON=$(gh api "/user/keys" --silent) || {
    echo "Kunde inte hämta nycklar. Kontrollera internet eller 'gh auth status'."
    exit 1
}

# Kontrollera om nyckeln redan finns
if echo "$AUTH_KEYS_JSON" | jq -e ".[] | select(.title == \"$KEY_NAME\")" >/dev/null 2>&1; then
    echo "En SSH-nyckel med namnet '$KEY_NAME' finns redan."
    read -p "Vill du överskriva den? (y/N): " -r OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "Avbryter."
        exit 0
    fi

    # Ta bort befintlig
    KEY_ID=$(echo "$AUTH_KEYS_JSON" | jq -r ".[] | select(.title == \"$KEY_NAME\") | .id")
    echo "Tar bort befintlig nyckel (ID: $KEY_ID)..."
    gh api -X DELETE "/user/keys/$KEY_ID" --silent
fi

# --- 3. Generera nyckel om den saknas ---
if [[ ! -f "$PUB_KEY_PATH" ]]; then
    echo "Genererar ny ed25519 SSH-nyckel..."
    ssh-keygen -t ed25519 -C "$KEY_NAME" -f "$KEY_PATH" -N "" >/dev/null
else
    echo "Använder befintlig nyckel: $PUB_KEY_PATH"
fi

# --- 4. Läs in publik nyckel ---
PUB_KEY=$(<"$PUB_KEY_PATH")
if [[ -z "$PUB_KEY" ]]; then
    echo "Kunde inte läsa publik nyckel från $PUB_KEY_PATH"
    exit 1
fi

# --- 5. Ladda upp via REST API ---
echo "Laddar upp nyckeln till GitHub som '$KEY_NAME'..."
gh api \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  "/user/keys" \
  -f "title=$KEY_NAME" \
  -f "key=$PUB_KEY" >/dev/null

# --- KLART ---
echo "SSH-nyckeln '$KEY_NAME' har laddats upp till GitHub!"
echo ""
echo "Testa anslutningen:"
echo "   ssh -T git@github.com"
echo ""
echo "Tips: Lägg till i ssh-agent:"
echo "   eval \$(ssh-agent -s)"
echo "   ssh-add $KEY_PATH"


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
