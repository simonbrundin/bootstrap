#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Logga allt till fil + terminal (valfritt)
exec > >(tee -a "$HOME/bootstrap.log") 2>&1

echo "🚀 Startar bootstrap-installation..."

# --------------------------------------------------------------------------------------------------
# 🧱 INSTALLERA HOMEBREW
# --------------------------------------------------------------------------------------------------

if command -v brew >/dev/null 2>&1; then
    echo "✅ Homebrew är redan installerat."
else
    echo "📦 Installerar Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "✅ Homebrew installerat."

    echo >> "$HOME/.bashrc"
    echo 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
    eval "$($HOME/.linuxbrew/bin/brew shellenv)" || {
        echo "⚠️ Varning: kunde inte ladda brew shellenv."
    }
fi

# --------------------------------------------------------------------------------------------------
# 🔑 SETUP SSH-NYCKLAR FÖR GITHUB
# --------------------------------------------------------------------------------------------------

DEFAULT_NAME="Omarchy"
KEY_NAME="$DEFAULT_NAME"
COMMENT="$(whoami)@$(hostname) (Omarchy $(date +%Y-%m-%d))"

if [[ -z "$KEY_NAME" ]]; then
    echo "❌ Fel: Namn på nyckeln får inte vara tomt!"
    exit 1
fi

SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/$KEY_NAME"
KEY_PUB="$KEY_PATH.pub"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "🔎 Kontrollerar om SSH-nyckel '$KEY_NAME' finns..."
if [[ ! -f "$KEY_PATH" ]]; then
    echo "🪄 Genererar ny ed25519 SSH-nyckel..."
    ssh-keygen -t ed25519 -C "$COMMENT" -f "$KEY_PATH" -N "" || {
        echo "❌ Fel: kunde inte generera SSH-nyckel!"
        exit 1
    }
    chmod 600 "$KEY_PATH"
    chmod 644 "$KEY_PUB"
    echo "✅ Nyckel genererad: $KEY_PATH"
else
    echo "✅ SSH-nyckel finns redan: $KEY_PATH"
fi

if [[ ! -f "$KEY_PUB" ]]; then
    echo "❌ Fel: Kunde inte hitta publik nyckel: $KEY_PUB"
    exit 1
fi
PUBLIC_KEY=$(cat "$KEY_PUB")

echo "🔑 Installerar keychain..."
brew install keychain || { echo "❌ Kunde inte installera keychain."; exit 1; }
eval "$(keychain --eval --agents ssh "$KEY_PATH")"

echo
echo "📋 Kopiera den här publika nyckeln till GitHub: https://github.com/settings/keys"
echo
echo "$PUBLIC_KEY"
echo

# --------------------------------------------------------------------------------------------------
# 📁 SKAPA REPOS-MAPP
# --------------------------------------------------------------------------------------------------

echo "📂 Skapar katalog för repositories..."
mkdir -p "$HOME/repos"

# --------------------------------------------------------------------------------------------------
# 🧩 KLONA DOTFILES
# --------------------------------------------------------------------------------------------------

if [ -d "$HOME/repos/dotfiles" ]; then
    echo "🔄 Uppdaterar befintliga dotfiles..."
    cd "$HOME/repos/dotfiles" && git pull
else
    echo "⬇️ Klonar dotfiles..."
    git clone git@github.com:simonbrundin/dotfiles.git "$HOME/repos/dotfiles" || {
        echo "❌ Kunde inte klona dotfiles!"
        exit 1
    }
fi

# --------------------------------------------------------------------------------------------------
# 🧠 KLONA SIMON CLI
# --------------------------------------------------------------------------------------------------

if [ -d "$HOME/repos/simon-cli" ]; then
    echo "🔄 Uppdaterar Simon CLI..."
    cd "$HOME/repos/simon-cli" && git pull
else
    echo "⬇️ Klonar Simon CLI..."
    git clone git@github.com:simonbrundin/simon-cli.git "$HOME/repos/simon-cli" || {
        echo "❌ Kunde inte klona Simon CLI!"
        exit 1
    }
fi

# --------------------------------------------------------------------------------------------------
# 🍺 INSTALLERA PAKET VIA BREW
# --------------------------------------------------------------------------------------------------

if [[ -f "$HOME/repos/dotfiles/brew/.Brewfile" ]]; then
    echo "📦 Installerar paket via Brew..."
    brew bundle --file="$HOME/repos/dotfiles/brew/.Brewfile"
else
    echo "⚠️ Ingen Brewfile hittades i dotfiles/brew/.Brewfile"
fi

# --------------------------------------------------------------------------------------------------
# 🐚 SÄTT NUSHELL SOM STANDARDSHELL
# --------------------------------------------------------------------------------------------------

NU_PATH="$(brew --prefix)/bin/nu"
if [[ ! -x "$NU_PATH" ]]; then
    echo "❌ Kunde inte hitta nushell-binären ($NU_PATH)"
    exit 1
fi

CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" != "$NU_PATH" ]]; then
    echo "🌀 Sätter nushell som standardshell..."
    echo "$NU_PATH" | sudo tee -a /etc/shells > /dev/null
    sudo usermod -s "$NU_PATH" "$USER"
else
    echo "✅ Nushell är redan standardshell."
fi

# --------------------------------------------------------------------------------------------------
# 🧷 SÄTT UPP DOTFILES MED STOW
# --------------------------------------------------------------------------------------------------

echo "🧩 Länkar dotfiles med stow..."
cd "$HOME/repos/dotfiles"
for dir in */; do
    stow --adopt --verbose "$dir" --target="$HOME"
done

# --------------------------------------------------------------------------------------------------
# Starta om Chromium för att installera extensions
# --------------------------------------------------------------------------------------------------

pkill chromium
chromium &


# --------------------------------------------------------------------------------------------------
# 🎹 FIXA KANATA-PERMISSIONER
# --------------------------------------------------------------------------------------------------

if [[ -x "$HOME/repos/dotfiles/kanata/.config/kanata/fix-privileges.sh" ]]; then
    echo "⚙️  Kör kanata fix-privileges..."
    bash "$HOME/repos/dotfiles/kanata/.config/kanata/fix-privileges.sh"
else
    echo "⚠️  Hittade inte fix-privileges.sh för Kanata."
fi

# --------------------------------------------------------------------------------------------------
# 📜 SETUP FÖR ATUIN
# --------------------------------------------------------------------------------------------------

mkdir -p "$HOME/.local/share/atuin/"

# echo "Running simon bootstrap via nushell..."
# nu -c "$HOME/repos/simon-cli/simon bootstrap mac"

echo
echo "✅ Bootstrap klart! Allt ser bra ut. 🎉"
